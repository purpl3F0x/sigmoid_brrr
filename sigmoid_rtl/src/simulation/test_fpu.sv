`timescale 1ns / 1ps
`default_nettype none

import bf16_constants::*;

// Test combinational FPU modules
module test_fpu();
    logic [15:0] abs_result;
    logic [15:0] add_result;
    logic [15:0] sub_result;
    logic [15:0] mul_result;
    logic [15:0] i2f_result;
    logic [15:0] f2i_nearest_result;
    logic [15:0] f2i_truncate_result;

    bf16_abs abs (
        .op1(MINUS_FOUR),
        .result(abs_result)
    );

    bf16_add_single_cycle add (
        .op1(TWO),
        .op2(THREE),
        .result(add_result),
        .isResultValid(),
        .isReady()
    );

    bf16_sub_single_cycle sub (
        .op1(TWO),
        .op2(THREE),
        .result(sub_result),
        .isResultValid(),
        .isReady()
    );

    bf16_mul_single_cycle mul (
        .op1(TWO),
        .op2(THREE),
        .result(mul_result),
        .isResultValid(),
        .isReady()
    );

    bf16_i2f_single_cycle i2f (
        .op1(32'd4),
        .result(i2f_result),
        .isResultValid(),
        .isReady()
    );

    bf16_f2i_single_cycle #(
        .rndMode_i(FPU_RNDMODE_NEAREST)
    ) f2i_nearest (
        .op1(16'h407D), // 3.95
        .result(f2i_nearest_result),
        .isResultValid(),
        .isReady()
    );

    bf16_f2i_single_cycle #(
        .rndMode_i(FPU_RNDMODE_TRUNCATE)
    ) f2i_truncate (
        .op1(16'h407D), // 3.95
        .result(f2i_truncate_result),
        .isResultValid(),
        .isReady()
    );

    logic [2:0] cmp_ge_results;
    logic [15:0] cmp_ge_op1 [2:0] = { ONE, TWO, THREE };
    logic [15:0] cmp_ge_op2 [2:0] = { THREE, TWO, ONE };
    logic [2:0] cmp_ge_expected = { 1'b0, 1'b1, 1'b1 } ;

    // Generate comparators    
    genvar i;
    generate
        for (i = 0; i < 3; i++) begin
            bf16_cmp_ge cmp (
                .op1(cmp_ge_op1[i]),
                .op2(cmp_ge_op2[i]),
                .cmp_o(cmp_ge_results[i]),
                .isCmpValid_o()
            );
        end
    endgenerate

    /* verilator public_flat_on */
    integer tests_ran = 0;
    integer failed_tests = 0;
    /* verilator public_off */

    function void assert_eq(
        input [15:0] actual,
        input [15:0] expected,
        input string name
    );
        tests_ran++;

        assert(actual == expected) else begin
            $display("Error: %s (%h) is not equal to expected value (%h)", name, actual, expected);
            failed_tests++;  // Increment the failure count
        end
    endfunction

    initial begin
        #20;

        assert_eq(abs_result, FOUR, "abs_result");
        assert_eq(add_result, FIVE, "add_result");
        assert_eq(sub_result, MINUS_ONE, "sub_result");
        assert_eq(mul_result, SIX, "mul_result");
        assert_eq(i2f_result, FOUR, "i2f_result");
        assert_eq(f2i_nearest_result, 16'd4, "f2i_nearest_result");
        assert_eq(f2i_truncate_result, 16'd3, "f2i_truncate_result");

        // Only test cmp_ge for now. Other comparisons should work if it works fine
        for (integer i = 0; i < $size(cmp_ge_results); i++) begin
            assert_eq({15'd0, cmp_ge_results[i]}, {15'd0, cmp_ge_expected[i]}, $sformatf("cmp_ge[%0d]", i));
        end

        $display("Total tests:  %d", tests_ran);
        $display("Passed tests: %d", tests_ran - failed_tests);
        $display("Failed tests: %d", failed_tests);
        $finish(0);
    end
endmodule
