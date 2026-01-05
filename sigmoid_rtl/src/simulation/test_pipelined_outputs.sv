`timescale 1ns / 1ps
`default_nettype none

// Takes in a list of input bf16 values in a text file
// Outputs a list of output bf16 values in another text file
// Used for graphing the result of our approximator in
module test_pipelined_outputs();
    reg clk;
    reg rst;
    reg valid_in;
    wire valid_out;
    
    reg[15:0] data_in;
    wire[15:0] data_out;

    // Appropriately configured clock so that post-implementation simulation can keep up
    localparam CLOCK_PERIOD = 6;
    localparam CLOCK_HALF_PERIOD = CLOCK_PERIOD / 2;

    sigmoid_pipelined sig (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .data_in(data_in),
        .data_out(data_out)
    );
    
    integer input_file, output_file, file_result;

    always #(CLOCK_HALF_PERIOD) clk = ~clk;

    initial begin
        input_file = $fopen("/your/path/here/rtl_testbench_inputs.txt", "r");
        if (input_file == 0) begin
            $display("Unable to open input file");
            $finish(1);
        end

        output_file = $fopen("/your/path/here/rtl_testbench_outputs.txt", "w");
        if (output_file == 0) begin
            $display("Unable to open output file");
            $finish(1);
        end

        valid_in = 0;
        clk = 0;
        rst = 1;
        
        // Hold reset high for 5 cycles
        #(5 * CLOCK_PERIOD);
        
        // Hold reset low, start pumping data
        rst = 0;
        #(5 * CLOCK_PERIOD);

        while (!$feof(input_file)) begin
            file_result = $fscanf(input_file, "%h\n", data_in);

            if (file_result == 1) begin
                valid_in = 1;

                // Wait until the result is valid
                wait(valid_out == 1);
                #(CLOCK_HALF_PERIOD);

                // Write to output file
                $fwrite(output_file, "%h\n", data_out);

                valid_in = 0;
                wait(valid_out == 0);
            end
        end

        $finish(0);
    end
endmodule
