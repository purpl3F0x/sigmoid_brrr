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
    
    sigmoid_pipelined sig (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .valid_out(valid_out),
        .data_in(data_in),
        .data_out(data_out)
    );
    
    integer input_file, output_file, file_result;

    // 100 MHz clock so that post-implementation simulation can keep up
    always #5 clk = ~clk;

    initial begin
        input_file = $fopen("/home/gponiris/gponiris/rtl_testbench_inputs.txt", "r");
        if (input_file == 0) begin
            $display("Unable to open input file");
            $finish(1);
        end

        output_file = $fopen("/home/gponiris/gponiris/rtl_testbench_outputs.txt", "w");
        if (output_file == 0) begin
            $display("Unable to open output file");
            $finish(1);
        end

        valid_in = 0;
        clk = 0;
        rst = 1;
        
        // Hold reset high for 5 cycles
        #50;
        
        // Hold reset low, start pumping data
        rst = 0;
        #50;
        valid_in = 1;

        while (!$feof(input_file)) begin
            file_result = $fscanf(input_file, "%h\n", data_in);

            if (file_result == 1) begin
                // Wait for 5 cycles so the result is ready
                #50;
                
                // Write to output file
                $fwrite(output_file, "%h\n", data_out);
            end
        end

        $finish(0);
    end
endmodule
