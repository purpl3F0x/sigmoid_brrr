`default_nettype none

// Fast, combinational bf16 comparison unit based on https://gitlab.com/davide.zoni/bfloat_fpu_systemverilog

/* verilator lint_off WIDTHTRUNC */
/* verilator lint_off WIDTHEXPAND */

module bf16_cmp (
    input wire doEq_i, input wire doLt_i, input wire doLe_i,
    input wire [15:0] op1,
    input wire [15:0] op2,

    output logic cmp_o,
    output logic isCmpValid_o
);
    localparam SIGN_BITS = 1;
    localparam EXPONENT_BITS = 8;
    localparam FRACTION_BITS = 7;

    // Sign, exponent, mantissa for each operand
    logic [SIGN_BITS-1:0] opASign_i;
    logic [EXPONENT_BITS-1:0] opAExp_i;
    logic [FRACTION_BITS-1:0] opAFract_i;
    logic [SIGN_BITS-1:0] opBSign_i;
    logic [EXPONENT_BITS-1:0] opBExp_i;
    logic [FRACTION_BITS-1:0] opBFract_i;

    // Zero, sNaN, qNaN flags for each operand
    logic isAZer_i;
    logic isBZer_i;

    logic isASNaN_i;
    logic isBSNaN_i;

    logic isAQNaN_i;
    logic isBQNaN_i;

    logic isABZer;
    logic isABSNaN, isABQNaN, isABNaN;
    logic signAEqB, signAEqpB, signAEqmB, signALtB;
    logic expAGtB, expAEqB, expALtB;
    logic fractAGtB, fractAEqB, fractALtB;
    logic cmpAEqB, cmpALtB, cmpALeB;

    always_comb begin
        // Break inputs into sign-exponent-fraction
        opASign_i = op1[15];
        opBSign_i = op2[15];

        opAExp_i = op1[14:7];
        opBExp_i = op2[14:7];

        opAFract_i = op1[6:0];
        opBFract_i = op2[6:0];

        // Zero and NaN flags for each operand
        isAZer_i = ~(|op1[14:0]);
        isBZer_i = ~(|op2[14:0]);

        // QNaN: Exponent = 0xFF, non-zero fraction, MSB of fraction is 0
        isAQNaN_i = (&opAExp_i) & ~opAFract_i[6] & (|opAFract_i[5:0]);
        isBQNaN_i = (&opBExp_i) & ~opBFract_i[6] & (|opBFract_i[5:0]);

        // SNaN: Exponent = 0xFF, MSB of fraction is 1
        isASNaN_i = (&opAExp_i) & opAFract_i[6];
        isBSNaN_i = (&opBExp_i) & opBFract_i[6];

        // Zero/NaN flags for the comparison result
        isABZer  = isAZer_i && isBZer_i;
        isABSNaN = isASNaN_i || isBSNaN_i;
        isABQNaN = isAQNaN_i || isBQNaN_i;
        isABNaN  = isABSNaN || isABQNaN;

        // Sign/exponent/significand comparisons
        signAEqB  = opASign_i == opBSign_i;
        signAEqpB =	~opASign_i && ~opBSign_i;
        signAEqmB =	opASign_i && opBSign_i;
        signALtB  = opASign_i > opBSign_i;
        expAGtB   = opAExp_i > opBExp_i;
        expAEqB   = opAExp_i == opBExp_i;
        expALtB   = opAExp_i < opBExp_i;
        fractAGtB =	opAFract_i > opBFract_i;
        fractAEqB =	opAFract_i == opBFract_i;
        fractALtB =	opAFract_i < opBFract_i;

        //	A-B comparisons
        cmpAEqB = ~isABNaN && (isABZer || (signAEqB && expAEqB && fractAEqB));
        cmpALtB = ~isABNaN && ~isABZer &&
            (signALtB || (signAEqpB && expALtB) || (signAEqmB && expAGtB) || (signAEqpB && expAEqB && fractALtB) ||
            (signAEqmB && expAEqB && fractAGtB));
    
        cmpALeB = cmpAEqB || cmpALtB;

        if (doEq_i)
            cmp_o = cmpAEqB;
        else if (doLt_i)
            cmp_o = cmpALtB;
        else // if (doLe_i)
            cmp_o = cmpALeB;

        isCmpValid_o = doEq_i || doLt_i || doLe_i;
        // isCmpInvalid = ((doLe_i || doLt_i) && isABNaN) || (doEq_i && isABSNaN);
    end
endmodule

/* verilator lint_on WIDTHTRUNC */
/* verilator lint_on WIDTHEXPAND */