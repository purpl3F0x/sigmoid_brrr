`timescale 1ns / 1ps
`default_nettype none

module test_sigmoid_pipelined();
    reg clk;
    reg rst;
    reg valid_in;
    wire valid_out;
    
    reg[15:0] data_in, expected;
    wire[15:0] data_out;
    
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
    
    integer tests_ran = 0;
    integer failed_tests = 0;
    integer file, file_result;
    
    always #(CLOCK_HALF_PERIOD) clk = ~clk;

    initial begin
        // Test cases. Each line is 1 test case in the format (input, expected output)
        file = $fopen("/your/path/here/sample_test_cases.txt", "r");
        if (file == 0) begin
            $display("Unable to open test case file");
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

        while (!$feof(file)) begin
            file_result = $fscanf(file, "%h %h\n", data_in, expected);

            if (file_result == 2) begin
                tests_ran++;
                valid_in = 1;

                // Wait until the result is valid
                wait(valid_out == 1);
                #(CLOCK_HALF_PERIOD);

                if (data_out != expected) begin
                    failed_tests++;
                    $display("Error: Test case failed");
                    $display("Input: %h", data_in);
                    $display("Expected %h, got %h", expected, data_out);
                end
                
                valid_in = 0;
                wait(valid_out == 0);
            end
        end

        $display("Total tests:  %d", tests_ran);
        $display("Passed tests: %d", tests_ran - failed_tests);
        $display("Failed tests: %d", failed_tests);
        $finish(0);
    end
endmodule
