// Copyright 2019 Politecnico di Milano.
// Copyright and related rights are licensed under the Solderpad Hardware
// Licence, Version 2.0 (the "Licence"); you may not use this file except in
// compliance with the Licence. You may obtain a copy of the Licence at
// https://solderpad.org/licenses/SHL-2.0/. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this Licence is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the Licence for the
// specific language governing permissions and limitations under the Licence.
//
// Authors (in alphabetical order):
// Andrea Galimberti    <andrea.galimberti@polimi.it>
// Davide Zoni          <davide.zoni@polimi.it>
// Date: 30.09.2019

/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */

`default_nettype wire

// Single-cycle FPU operations, with hardcoded operation and rounding mode signals,
// based on https://gitlab.com/davide.zoni/bfloat_fpu_systemverilog 

// The state machine has been reworked so that results are available on the very same cycle after the input signals are set
// Removing the padv/flush signals and the IDLE/DONE states
// DO NOT USE FOR COMPUTING DIVISION, THE DIVISION MODULE NEEDS SEVERAL CYCLES TO FINISH
import lampFPU_pkg::*;

module bf16_single_cycle_fpu_op #(
    opcodeFPU_t opcode_i = FPU_ADD,
    rndModeFPU_t rndMode_i = FPU_RNDMODE_NEAREST
) (
    input clk,
    input rst,
    input [LAMP_INTEGER_DW-1:0] op1_i,
    input [LAMP_FLOAT_DW-1:0] op2_i,
    
    output logic [LAMP_INTEGER_DW-1:0] result_o,
    output logic isResultValid_o,
    output logic isReady_o
);
    generate
        if (opcode_i == FPU_DIV) begin
            initial $fatal("Single cycle bf16 FPU cannot be used with division. Division must be done in multiple cycles");
        end
    endgenerate

    // Input
    logic flush_r, flush_r_next;
    opcodeFPU_t opcode_r;
    rndModeFPU_t rndMode_r;
    logic [LAMP_INTEGER_DW-1:0] op1_r;

    wire flush_i = 0;	// Flush the FPU invalidating the current operation

    //	add/sub outputs
    logic addsub_s_res;
    logic [LAMP_FLOAT_E_DW-1:0] addsub_e_res;
    logic [LAMP_FLOAT_F_DW+5-1:0] addsub_f_res;
    logic addsub_valid;
    logic addsub_isOverflow;
    logic addsub_isUnderflow;
    logic addsub_isToRound;

    //	mul outputs
    logic mul_s_res;
    logic [LAMP_FLOAT_E_DW-1:0] mul_e_res;
    logic [LAMP_FLOAT_F_DW+5-1:0] mul_f_res;
    logic mul_valid;
    logic mul_isOverflow;
    logic mul_isUnderflow;
    logic mul_isToRound;

    //	div outputs
    logic div_s_res;
    logic [LAMP_FLOAT_E_DW-1:0] div_e_res;
    logic [LAMP_FLOAT_F_DW+5-1:0] div_f_res;
    logic div_valid;
    logic div_isOverflow;
    logic div_isUnderflow;
    logic div_isToRound;

    //	f2i outputs
    logic f2i_s_res;
    logic [(LAMP_INTEGER_DW+3)-1:0] f2i_f_res;
    logic f2i_valid;
    logic f2i_isOverflow;
    logic f2i_isUnderflow;
    logic f2i_isSNaN;

    //	i2f outputs
    logic i2f_s_res;
    logic [LAMP_FLOAT_E_DW-1:0] i2f_e_res;
    logic [LAMP_FLOAT_F_DW+5-1:0] i2f_f_res;
    logic i2f_valid;
    logic i2f_isOverflow;
    logic i2f_isUnderflow;
    logic i2f_isToRound;

	logic doAddSub_r;
	logic isOpSub_r;
	logic doMul_r;
	logic doDiv_r;
	logic doF2i_r;
	logic doI2f_r;
	logic doCmpEq_r;
	logic doCmpLt_r;
	logic doCmpLe_r;

    //	cmp outputs
    logic cmp_res;
    logic cmp_isResValid;
    logic cmp_isCmpInvalid;

    logic [LAMP_FLOAT_DW-1:0] i2f_res;
    logic i2f_isResValid;
    logic i2f_isResInexact;
    logic [LAMP_INTEGER_DW-1:0] f2i_res;
    logic f2i_isResValid;
    logic f2i_isResSNaN;
    logic f2i_isResZero;
    logic f2i_isResInexact;
    logic f2i_isResInvalid;

    // FUs results and valid bits
    logic [LAMP_INTEGER_DW-1:0] res;
    logic isResValid;

    logic [LAMP_FLOAT_S_DW-1:0] s_op1_r;
    logic [LAMP_FLOAT_E_DW-1:0] e_op1_r;
    logic [LAMP_FLOAT_F_DW-1:0] f_op1_r;
    logic [(LAMP_FLOAT_F_DW+1)-1:0] extF_op1_r;
    logic [(LAMP_FLOAT_E_DW+1)-1:0] extE_op1_r;
    logic isInf_op1_r;
    logic isZ_op1_r;
    logic isSNAN_op1_r;
    logic isQNAN_op1_r;
    logic [LAMP_FLOAT_S_DW-1:0] s_op2_r;
    logic [LAMP_FLOAT_E_DW-1:0] e_op2_r;
    logic [LAMP_FLOAT_F_DW-1:0] f_op2_r;
    logic [(LAMP_FLOAT_F_DW+1)-1:0] extF_op2_r;
    logic [(LAMP_FLOAT_E_DW+1)-1:0] extE_op2_r;
    logic isInf_op2_r;
    logic isZ_op2_r;
    logic isSNAN_op2_r;
    logic isQNAN_op2_r;
    //	add/sub only
    logic op1_GT_op2_r;
    logic [LAMP_FLOAT_E_DW+1-1 : 0] e_diff_r;
    //	mul/div only
    logic [(1+LAMP_FLOAT_F_DW)-1:0] extShF_op1_r;
    logic [$clog2(1+LAMP_FLOAT_F_DW)-1:0]	nlz_op1_r;
    logic [(1+LAMP_FLOAT_F_DW)-1:0] 		extShF_op2_r;
    logic [$clog2(1+LAMP_FLOAT_F_DW)-1:0]	nlz_op2_r;

    //	pre-operation wires/regs
    logic [LAMP_FLOAT_S_DW-1:0] s_op1_wire;
    logic [LAMP_FLOAT_E_DW-1:0] e_op1_wire;
    logic [LAMP_FLOAT_F_DW-1:0] f_op1_wire;
    logic [(LAMP_FLOAT_F_DW+1)-1:0] extF_op1_wire;
    logic [(LAMP_FLOAT_E_DW+1)-1:0] extE_op1_wire;
    logic isDN_op1_wire;
    logic isZ_op1_wire;
    logic isInf_op1_wire;
    logic isSNAN_op1_wire;
    logic isQNAN_op1_wire;
    logic [LAMP_FLOAT_S_DW-1:0] s_op2_wire;
    logic [LAMP_FLOAT_E_DW-1:0] e_op2_wire;
    logic [LAMP_FLOAT_F_DW-1:0] f_op2_wire;
    logic [(LAMP_FLOAT_F_DW+1)-1:0] extF_op2_wire;
    logic [(LAMP_FLOAT_E_DW+1)-1:0] extE_op2_wire;
    logic isDN_op2_wire;
    logic isZ_op2_wire;
    logic isInf_op2_wire;
    logic isSNAN_op2_wire;
    logic isQNAN_op2_wire;
    //	add/sub only
    logic op1_GT_op2_wire;
    logic [LAMP_FLOAT_E_DW+1-1 : 0] e_diff_wire;
    //	mul/div only
    logic [(1+LAMP_FLOAT_F_DW)-1:0] extShF_op1_wire;
    logic [$clog2(1+LAMP_FLOAT_F_DW)-1:0] nlz_op1_wire;
    logic [(1+LAMP_FLOAT_F_DW)-1:0] extShF_op2_wire;
    logic [$clog2(1+LAMP_FLOAT_F_DW)-1:0] nlz_op2_wire;

    //	pre-rounding wires/regs
    logic s_res;
    logic [LAMP_FLOAT_E_DW-1:0] e_res;
    logic [LAMP_FLOAT_F_DW+5-1:0] f_res;
    logic isOverflow;
    logic isUnderflow;
    logic isToRound;

    // post-rounding wires/regs
    logic s_res_postRnd;
    logic [LAMP_FLOAT_F_DW-1:0] f_res_postRnd;
    logic [LAMP_FLOAT_E_DW-1:0] e_res_postRnd;
    logic [LAMP_INTEGER_DW-1:0] res_postRnd;
    logic isOverflow_postRnd;
    logic isUnderflow_postRnd;

    // integer post-rounding wires/regs
    logic f2i_s_res_postRnd;
    logic [LAMP_INTEGER_DW-1:0] f2i_f_res_postRnd;
    logic [LAMP_INTEGER_DW-1:0] f2i_res_postRnd;
    logic f2i_isOverflow_postRnd;
    logic f2i_isUnderflow_postRnd;
    logic f2i_isInvalid_postRnd;

    typedef enum logic [1:0]
    {
        WORK	= 'd0
    }	state_t;

    state_t ss;

    always_comb begin
        //input
        doAddSub_r			=	(opcode_i == FPU_ADD | opcode_i == FPU_SUB);
        isOpSub_r			=	(opcode_i == FPU_SUB);
        doMul_r				=	(opcode_i == FPU_MUL);
        doDiv_r				=	(opcode_i == FPU_DIV);
        doF2i_r				=	(opcode_i == FPU_F2I);
        doI2f_r				=	(opcode_i == FPU_I2F);
        doCmpEq_r			=	(opcode_i == FPU_EQ);
        doCmpLt_r			=	(opcode_i == FPU_LT);
        doCmpLe_r			=	(opcode_i == FPU_LE);
        flush_r				=	1'b0;
        opcode_r			=	opcode_i;
        rndMode_r			=	rndMode_i;
        op1_r				=	op1_i;
        //output
        //fpcsr_o			<=	'0;
    end

    always_comb begin
        s_res					=	1'b0;
        e_res					=	'0;
        f_res					=	'0;
        isOverflow				=	1'b0;
        isUnderflow				=	1'b0;
        isToRound				=	1'b0;

        res						=	'0;
        isResValid				=	1'b0;
        case (ss)
            WORK:
            begin
                case (opcode_r)
                    FPU_ADD, FPU_SUB:
                    begin
                        s_res						=	addsub_s_res;
                        e_res						=	addsub_e_res;
                        f_res						=	addsub_f_res;
                        isOverflow					=	addsub_isOverflow;
                        isUnderflow					=	addsub_isUnderflow;
                        isToRound					=	addsub_isToRound;

                        res =	res_postRnd;
                        isResValid					=	addsub_valid;
                    end
                    FPU_MUL:
                    begin
                        s_res						=	mul_s_res;
                        e_res						=	mul_e_res;
                        f_res						=	mul_f_res;
                        isOverflow					=	mul_isOverflow;
                        isUnderflow					=	mul_isUnderflow;
                        isToRound					=	mul_isToRound;

                        res =	res_postRnd;
                        isResValid					=	mul_valid;
                    end
                    FPU_DIV:
                    begin
                        s_res						=	div_s_res;
                        e_res						=	div_e_res;
                        f_res						=	div_f_res;
                        isOverflow					=	div_isOverflow;
                        isUnderflow					=	div_isUnderflow;
                        isToRound					=	div_isToRound;

                        res =	res_postRnd;
                        isResValid					=	div_valid;
                    end
                    FPU_F2I:
                    begin
                        res =	f2i_res_postRnd;
                        isResValid					=	f2i_valid;
                    end
                    FPU_I2F:
                    begin
                        s_res						=	i2f_s_res;
                        e_res						=	i2f_e_res;
                        f_res						=	i2f_f_res;
                        isOverflow					=	i2f_isOverflow;
                        isUnderflow					=	i2f_isUnderflow;
                        isToRound					=	i2f_isToRound;

                        res =	res_postRnd;
                        isResValid					=	i2f_valid;
                    end
                    FPU_EQ, FPU_LT, FPU_LE:
                    begin
                        res =	{{(LAMP_INTEGER_DW-1){1'b0}}, cmp_res};
                        isResValid					=	cmp_isResValid;
                    end

                    default: ;
                endcase

                if (isResValid) begin
                    result_o					=	res;
                    isResultValid_o			=	1'b1;
                end else begin
                    result_o = 16'hFFFF;
                end
            end

            default: ;
        endcase
    end

//////////////////////////////////////////////////////////////////
// 			operands pre-processing	- combinational logic 	    //
//////////////////////////////////////////////////////////////////

    always_comb begin
        if (0) begin
            // Old reset logic was here
        end
        else begin
            ss					=	WORK;

            s_op1_r			=	s_op1_wire;
            e_op1_r			=	e_op1_wire;
            f_op1_r			=	f_op1_wire;
            extF_op1_r		=	extF_op1_wire;
            extE_op1_r		=	extE_op1_wire;
            isInf_op1_r		=	isInf_op1_wire;
            isZ_op1_r		=	isZ_op1_wire;
            isSNAN_op1_r	=	isSNAN_op1_wire;
            isQNAN_op1_r	=	isQNAN_op1_wire;
            s_op2_r			=	s_op2_wire;
            e_op2_r			=	e_op2_wire;
            f_op2_r			=	f_op2_wire;
            extF_op2_r		=	extF_op2_wire;
            extE_op2_r		=	extE_op2_wire;
            isInf_op2_r		=	isInf_op2_wire;
            isZ_op2_r		=	isZ_op2_wire;
            isSNAN_op2_r	=	isSNAN_op2_wire;
            isQNAN_op2_r	=	isQNAN_op2_wire;
            //	add/sub only
            op1_GT_op2_r	=	op1_GT_op2_wire;
            e_diff_r		=	e_diff_wire;
            //	mul/div only
            extShF_op1_r	=	extShF_op1_wire;
            nlz_op1_r		=	nlz_op1_wire;
            extShF_op2_r	=	extShF_op2_wire;
            nlz_op2_r		=	nlz_op2_wire;
        end
    end

//////////////////////////////////////////////////////////////////
// 			operands pre-processing	- combinational logic //
//////////////////////////////////////////////////////////////////

    always_comb begin
        {s_op1_wire, e_op1_wire, f_op1_wire} = FUNC_splitOperand(op1_i[LAMP_FLOAT_DW-1:0]);
        {isInf_op1_wire,isDN_op1_wire,isZ_op1_wire,isSNAN_op1_wire,isQNAN_op1_wire}	= FUNC_checkOperand(op1_i[LAMP_FLOAT_DW-1:0]);
        extE_op1_wire = FUNC_extendExp(e_op1_wire, isDN_op1_wire);
        extF_op1_wire = FUNC_extendFrac(f_op1_wire, isDN_op1_wire, isZ_op1_wire);

        {s_op2_wire, e_op2_wire, f_op2_wire} = FUNC_splitOperand(op2_i);
        {isInf_op2_wire,isDN_op2_wire,isZ_op2_wire,isSNAN_op2_wire,isQNAN_op2_wire}	= FUNC_checkOperand(op2_i);
        extE_op2_wire = FUNC_extendExp(e_op2_wire, isDN_op2_wire);
        extF_op2_wire = FUNC_extendFrac(f_op2_wire, isDN_op2_wire, isZ_op2_wire);

        // add/sub only
        op1_GT_op2_wire = FUNC_op1_GT_op2(extF_op1_wire, extE_op1_wire, extF_op2_wire, extE_op2_wire);
        e_diff_wire = op1_GT_op2_wire ? (extE_op1_wire - extE_op2_wire) : (extE_op2_wire - extE_op1_wire);

        // mul/div only
        nlz_op1_wire = FUNC_numLeadingZeros(extF_op1_wire);
        nlz_op2_wire = FUNC_numLeadingZeros(extF_op2_wire);
        extShF_op1_wire = extF_op1_wire << nlz_op1_wire;
        extShF_op2_wire = extF_op2_wire << nlz_op2_wire;
    end

    // NOTE: fpu ready signal that makes the pipeline to advance.
    // It is simple and plain combinational logic: this should require
    // some cpu-side optimizations to improve the overall system timing
    // in the future. The entire advancing mechanism should be re-designed
    // from scratch

    // assign isReady_o = (opcode_i == FPU_IDLE) | isResultValid_o;
    assign isReady_o = isResultValid_o;

//////////////////////////////////////////////////////////////////
// 				float rounding - combinational logic 	//
//////////////////////////////////////////////////////////////////

    always_comb begin
        if (rndMode_r == FPU_RNDMODE_NEAREST)
            f_res_postRnd	= FUNC_rndToNearestEven(f_res);
        else
            f_res_postRnd	= f_res[3+:LAMP_FLOAT_F_DW];
        if (isToRound)
            res_postRnd		= {s_res, e_res, f_res_postRnd};
        else
            res_postRnd		= {s_res, e_res, f_res[5+:LAMP_FLOAT_F_DW]};
    end

//////////////////////////////////////////////////////////////////
// 				integer rounding - combinational logic 	//
//////////////////////////////////////////////////////////////////

    always_comb begin
        if (rndMode_r == FPU_RNDMODE_NEAREST)
            f2i_f_res_postRnd	= FUNC_f2i_rndToNearestEven(f2i_f_res);
        else
            f2i_f_res_postRnd	= f2i_f_res[3+:LAMP_INTEGER_DW];

        f2i_res_postRnd			= (f2i_f_res_postRnd ^ {LAMP_INTEGER_DW{f2i_s_res}}) + f2i_s_res;
        f2i_isInvalid_postRnd	= ((~f2i_s_res) & f2i_f_res_postRnd[LAMP_INTEGER_DW-1]) | f2i_isOverflow | f2i_isSNaN;
    end

//////////////////////////////////////////////////////////////////
//						internal submodules						//
//////////////////////////////////////////////////////////////////

    lampFPU_addsub_comb
        lampFPU_addsub(
            //	inputs
            .doAddSub_i(doAddSub_r),
            .isOpSub_i(isOpSub_r),
            .s_op1_i(s_op1_r),
            .extF_op1_i(extF_op1_r),
            .extE_op1_i(extE_op1_r),
            .isInf_op1_i(isInf_op1_r),
            .isSNAN_op1_i(isSNAN_op1_r),
            .isQNAN_op1_i(isQNAN_op1_r),
            .s_op2_i(s_op2_r),
            .extF_op2_i(extF_op2_r),
            .extE_op2_i(extE_op2_r),
            .isInf_op2_i(isInf_op2_r),
            .isSNAN_op2_i(isSNAN_op2_r),
            .isQNAN_op2_i(isQNAN_op2_r),
            .op1_GT_op2_i(op1_GT_op2_r),
            .e_diff_i(e_diff_r),
            //	outputs
            .s_res_o(addsub_s_res),
            .e_res_o(addsub_e_res),
            .f_res_o(addsub_f_res),
            .valid_o(addsub_valid),
            .isOverflow_o(addsub_isOverflow),
            .isUnderflow_o(addsub_isUnderflow),
            .isToRound_o(addsub_isToRound)
        );

    lampFPU_mul_comb
        lampFPU_mul0 (
            //	inputs
            .doMul_i(doMul_r),
            .s_op1_i(s_op1_r),
            .extShF_op1_i(extShF_op1_r),
            .extE_op1_i(extE_op1_r),
            .nlz_op1_i(nlz_op1_r),
            .isZ_op1_i(isZ_op1_r),
            .isInf_op1_i(isInf_op1_r),
            .isSNAN_op1_i(isSNAN_op1_r),
            .isQNAN_op1_i(isQNAN_op1_r),
            .s_op2_i(s_op2_r),
            .extShF_op2_i(extShF_op2_r),
            .extE_op2_i(extE_op2_r),
            .nlz_op2_i(nlz_op2_r),
            .isZ_op2_i(isZ_op2_r),
            .isInf_op2_i(isInf_op2_r),
            .isSNAN_op2_i(isSNAN_op2_r),
            .isQNAN_op2_i(isQNAN_op2_r),
            //	outputs
            .s_res_o(mul_s_res),
            .e_res_o(mul_e_res),
            .f_res_o(mul_f_res),
            .valid_o(mul_valid),
            .isOverflow_o(mul_isOverflow),
            .isUnderflow_o(mul_isUnderflow),
            .isToRound_o(mul_isToRound)
        );

    // Not actually combinational!! It's still multi-cycle!!
    lampFPU_div_comb
        lampFPU_div0 (
            .clk(clk),
            .rst(rst),
            //	inputs
            .doDiv_i(doDiv_r),
            .s_op1_i(s_op1_r),
            .extShF_op1_i(extShF_op1_r),
            .extE_op1_i(extE_op1_r),
            .nlz_op1_i(nlz_op1_r),
            .isZ_op1_i(isZ_op1_r),
            .isInf_op1_i(isInf_op1_r),
            .isSNAN_op1_i(isSNAN_op1_r),
            .isQNAN_op1_i(isQNAN_op1_r),
            .s_op2_i(s_op2_r),
            .extShF_op2_i(extShF_op2_r),
            .extE_op2_i(extE_op2_r),
            .nlz_op2_i(nlz_op2_r),
            .isZ_op2_i(isZ_op2_r),
            .isInf_op2_i(isInf_op2_r),
            .isSNAN_op2_i(isSNAN_op2_r),
            .isQNAN_op2_i(isQNAN_op2_r),
            //	outputs
            .s_res_o(div_s_res),
            .e_res_o(div_e_res),
            .f_res_o(div_f_res),
            .valid_o(div_valid),
            .isOverflow_o(div_isOverflow),
            .isUnderflow_o(div_isUnderflow),
            .isToRound_o(div_isToRound)
        );

    lampFPU_f2i_comb
        lampFPU_f2i0 (
            //	inputs
            .doF2i_i(doF2i_r),
            .s_op1_i(s_op1_r),
            .extF_op1_i(extF_op1_r),
            .extE_op1_i(extE_op1_r),
            .isSNAN_op1_i(isSNAN_op1_r),
            .isQNAN_op1_i(isQNAN_op1_r),
            //	outputs
            .s_res_o(f2i_s_res),
            .f_res_o(f2i_f_res),
            .valid_o(f2i_valid),
            .isOverflow_o(f2i_isOverflow),
            .isUnderflow_o(f2i_isUnderflow),
            .isSNaN_o(f2i_isSNaN)
        );

    lampFPU_i2f_comb
        lampFPU_i2f0 (
            //	inputs
            .doI2f_i(doI2f_r),
            .op1_i(op1_r),
            //	outputs
            .s_res_o(i2f_s_res),
            .e_res_o(i2f_e_res),
            .f_res_o(i2f_f_res),
            .valid_o(i2f_valid),
            .isOverflow_o(i2f_isOverflow),
            .isUnderflow_o(i2f_isUnderflow),
            .isToRound_o(i2f_isToRound)
        );

    lampFPU_cmp_comb
        lampFPU_cmp0 (
            //	inputs
            .doEq_i(doCmpEq_r),
            .doLt_i(doCmpLt_r),
            .doLe_i(doCmpLe_r),
            .opASign_i(s_op1_r),
            .opAExp_i(e_op1_r),
            .opAFract_i(f_op1_r),
            .opBSign_i(s_op2_r),
            .opBExp_i(e_op2_r),
            .opBFract_i(f_op2_r),
            .isAZer_i(isZ_op1_r),
            .isASNaN_i(isSNAN_op1_r),
            .isAQNaN_i(isQNAN_op1_r),
            .isBZer_i(isZ_op2_r),
            .isBSNaN_i(isSNAN_op2_r),
            .isBQNaN_i(isQNAN_op2_r),
            //	outputs
            .cmp_o(cmp_res),
            .isCmpValid_o(cmp_isResValid),
            .isCmpInvalid_o(cmp_isCmpInvalid)
        );
endmodule

/* verilator lint_on WIDTHTRUNC */
/* verilator lint_on WIDTHEXPAND */