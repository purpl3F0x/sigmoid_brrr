`timescale 1ns / 1ps
`default_nettype none

import bf16_constants::*;

module test_silu();
    reg clk;
    reg rst;
    reg valid_in;
    wire valid_out;
    
    reg[15:0] data_in;
    wire[15:0] data_out;

    localparam CLOCK_PERIOD = 6;
    localparam CLOCK_HALF_PERIOD = CLOCK_PERIOD / 2;
    always #1 clk = ~clk;

    silu_pipelined sig (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .data_in(data_in),
        .data_out(data_out)
    );

    // TODO: Proper testing for SiLU, just test SiLU(3) ~= 2.859375 for now
    initial begin
        valid_in = 0;
        clk = 0;
        rst = 1;

        // Hold reset high for 5 cycles
        #(5 * CLOCK_PERIOD);
        
        // Hold reset low, start pumping data
        rst = 0;
        #(5 * CLOCK_PERIOD);

        valid_in = 1;
        data_in = THREE;

        // Wait until the result is valid
        wait(valid_out == 1);
        #(CLOCK_HALF_PERIOD);

        if (data_out == 16'h4037) begin
            $display("SiLU workie :)");
        end

        else begin
            $display("SiLU no workie :(");
        end

        valid_in = 0;
        wait(valid_out == 0);

        $finish(0);
    end
endmodule
