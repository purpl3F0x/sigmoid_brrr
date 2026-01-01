`default_nettype none

import bf16_constants::*;
import lampFPU_pkg::*;

// Implements a single-cycle bfloat16 polynomial calculation unit using the formula
// f(x) = a2 * (x + offset)^2 + a1 * (x + offset) + a0
// Where a0, a1, a2 are the polynomial coefficients
module polynomial_2nd_degree (
    input wire clk,
    input wire rst,

    input wire valid_in,
    output wire valid_out,

    input wire [15:0] data_in,
    output wire [15:0] data_out,

    // Coefficients
    input wire [15:0] a0,
    input wire [15:0] a1,
    input wire [15:0] a2,
    input wire [15:0] offset
);
    // x + offset
    wire [15:0] x_offset;
    // (x + offset)^2
    wire [15:0] x_squared;

    // a1 * (x + offset) + a0
    wire [15:0] add2_output;

    // a1 * (x + offset)
    wire [15:0] mul2_output;
    // a2 * (x + offset)^2
    wire [15:0] mul3_output;

    // Single cycle design, so we've got a valid output as long as the input is valid
    assign valid_out = valid_in;

    // x_offset = data_in + offset
    bf16_add_single_cycle add1 (
        .op1(data_in),
        .op2(offset),
        .result(x_offset),
        .isResultValid(),
        .isReady()
    );

    // x_squared = (x + offset)^2
    bf16_mul_single_cycle mul1 (
        .op1(x_offset),
        .op2(x_offset),
        .result(x_squared),
        .isResultValid(),
        .isReady()
    );

    // mul2_output = a1 * (x + offset)
    bf16_mul_single_cycle mul2 (
        .op1(a1),
        .op2(x_offset),
        .result(mul2_output),
        .isResultValid(),
        .isReady()
    );

    // mul3_output = a2 * (x + offset)^2
    bf16_mul_single_cycle mul3 (
        .op1(a2),
        .op2(x_squared),
        .result(mul3_output),
        .isResultValid(),
        .isReady()
    );

    // add2_output = a0 + a1 * (x + offset)
    bf16_add_single_cycle add2 (
        .op1(a0),
        .op2(mul2_output),
        .result(add2_output),
        .isResultValid(),
        .isReady()
    );

    // Computes final result
    bf16_add_single_cycle add3 (
        .op1(mul3_output),
        .op2(add2_output),
        .result(data_out),
        .isResultValid(),
        .isReady()
    );

endmodule
