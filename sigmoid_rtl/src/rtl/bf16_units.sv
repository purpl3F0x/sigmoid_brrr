`default_nettype none

import lampFPU_pkg::*;

// Basic combinational bf16 arithmetic unit modules based on our (butchered) bf16 FPU library 

module bf16_add_single_cycle #(
    rndModeFPU_t rndMode_i = FPU_RNDMODE_NEAREST
) (
    input wire [LAMP_INTEGER_DW-1:0] op1,
    input wire [LAMP_FLOAT_DW-1:0] op2,
    
    output logic [LAMP_INTEGER_DW-1:0] result,
    output logic isResultValid,
    output logic isReady
);
    bf16_single_cycle_fpu_op #(
        .opcode_i(FPU_ADD),
        .rndMode_i(rndMode_i)
    ) adder (
        .op1_i(op1),
        .op2_i(op2),

        .result_o(result),
        .isResultValid_o(isResultValid),
        .isReady_o(isReady)
    );
endmodule

module bf16_sub_single_cycle #(
    rndModeFPU_t rndMode_i = FPU_RNDMODE_NEAREST
) (
    input wire [LAMP_INTEGER_DW-1:0] op1,
    input wire [LAMP_FLOAT_DW-1:0] op2,
    
    output logic [LAMP_INTEGER_DW-1:0] result,
    output logic isResultValid,
    output logic isReady
);
    bf16_single_cycle_fpu_op #(
        .opcode_i(FPU_SUB),
        .rndMode_i(rndMode_i)
    ) sub (
        .op1_i(op1),
        .op2_i(op2),

        .result_o(result),
        .isResultValid_o(isResultValid),
        .isReady_o(isReady)
    );
endmodule

module bf16_mul_single_cycle #(
    rndModeFPU_t rndMode_i = FPU_RNDMODE_NEAREST
) (
    input wire [LAMP_INTEGER_DW-1:0] op1,
    input wire [LAMP_FLOAT_DW-1:0] op2,
    
    output logic [LAMP_INTEGER_DW-1:0] result,
    output logic isResultValid,
    output logic isReady
);
    bf16_single_cycle_fpu_op #(
        .opcode_i(FPU_MUL),
        .rndMode_i(rndMode_i)
    ) mul (
        .op1_i(op1),
        .op2_i(op2),

        .result_o(result),
        .isResultValid_o(isResultValid),
        .isReady_o(isReady)
    );
endmodule

module bf16_i2f_single_cycle #(
    rndModeFPU_t rndMode_i = FPU_RNDMODE_NEAREST
) (
    input wire [LAMP_INTEGER_DW-1:0] op1,
    
    output logic [LAMP_INTEGER_DW-1:0] result,
    output logic isResultValid,
    output logic isReady
);
    bf16_single_cycle_fpu_op #(
        .opcode_i(FPU_I2F),
        .rndMode_i(rndMode_i)
    ) i2f (
        .op1_i(op1),
        .op2_i(0),

        .result_o(result),
        .isResultValid_o(isResultValid),
        .isReady_o(isReady)
    );
endmodule

module bf16_f2i_single_cycle #(
    rndModeFPU_t rndMode_i = FPU_RNDMODE_NEAREST
) (
    input wire [LAMP_INTEGER_DW-1:0] op1,
    
    output logic [LAMP_INTEGER_DW-1:0] result,
    output logic isResultValid,
    output logic isReady
);
    bf16_single_cycle_fpu_op #(
        .opcode_i(FPU_F2I),
        .rndMode_i(rndMode_i)
    ) f2i (
        .op1_i(op1),
        .op2_i(0),

        .result_o(result),
        .isResultValid_o(isResultValid),
        .isReady_o(isReady)
    );
endmodule

// Specialized bf16 comparison modules

module bf16_cmp_eq (
    input wire [15:0] op1,
    input wire [15:0] op2,

    output logic cmp_o,
    output logic isCmpValid_o
);
    bf16_cmp cmp (
        .doEq_i(1), .doLt_i(0), .doLe_i(0),
        .op1(op1),
        .op2(op2),
        .cmp_o(cmp_o),
        .isCmpValid_o(isCmpValid_o)
    );
endmodule

module bf16_cmp_lt (
    input wire [15:0] op1,
    input wire [15:0] op2,

    output logic cmp_o,
    output logic isCmpValid_o
);
    bf16_cmp cmp (
        .doEq_i(0), .doLt_i(1), .doLe_i(0),
        .op1(op1),
        .op2(op2),
        .cmp_o(cmp_o),
        .isCmpValid_o(isCmpValid_o)
    );
endmodule

module bf16_cmp_gt (
    input wire [15:0] op1,
    input wire [15:0] op2,

    output logic cmp_o,
    output logic isCmpValid_o
);
    bf16_cmp cmp (
        .doEq_i(0), .doLt_i(1), .doLe_i(0),
        // Do less than with the inputs swapped
        .op1(op2),
        .op2(op1),
        .cmp_o(cmp_o),
        .isCmpValid_o(isCmpValid_o)
    );
endmodule

module bf16_cmp_le (
    input wire [15:0] op1,
    input wire [15:0] op2,

    output logic cmp_o,
    output logic isCmpValid_o
);
    bf16_cmp cmp (
        .doEq_i(0), .doLt_i(0), .doLe_i(1),
        .op1(op1),
        .op2(op2),
        .cmp_o(cmp_o),
        .isCmpValid_o(isCmpValid_o)
    );
endmodule

module bf16_cmp_ge (
    input wire [15:0] op1,
    input wire [15:0] op2,

    output logic cmp_o,
    output logic isCmpValid_o
);
    bf16_cmp cmp (
        .doEq_i(0), .doLt_i(0), .doLe_i(1),
        // Do less than or equal with the inputs swapped
        .op1(op2),
        .op2(op1),
        .cmp_o(cmp_o),
        .isCmpValid_o(isCmpValid_o)
    );
endmodule