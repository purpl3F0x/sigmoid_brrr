`default_nettype none

// Module implementing the SiLU activation function, using our pipelined sigmoid module
// Our SiLU module has 6 + 1 = 7 pipeline stages
module silu_pipelined (
    input wire clk,
    input wire rst,
    input wire valid_in,
    input wire [15:0] data_in,

    output wire valid_out,
    output wire [15:0] data_out
);
    wire sigmoid_valid;
    wire [15:0] sigmoid_out;

    sigmoid_pipelined sigmoid (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .data_in(data_in),
        .valid_out(sigmoid_valid),
        .data_out(sigmoid_out)
    );

    // Our sigmoid module has a 6-stage pipeline
    // Thus, we need to pipeline our SiLU module's valid_in and data_in input signals the same way,
    // + 1 extra cycle to compute SiLU(x) = x * sigmoid(x)
    localparam SIGMOID_PIPELINE_STAGES = 6;
    localparam SILU_PIPELINE_STAGES = SIGMOID_PIPELINE_STAGES + 1;

    logic valid_in_pipeline [(SILU_PIPELINE_STAGES - 1):0];
    logic [15:0] data_in_pipeline [(SILU_PIPELINE_STAGES - 1):0];

    // Reset/advance pipeline properly each cycle
    always @(posedge clk) begin
        integer i;

        if (rst) begin
            for (i = 0; i < SILU_PIPELINE_STAGES; i++) begin
                valid_in_pipeline[i] <= 1'b0;
                data_in_pipeline[i] <= '0;
            end
        end
        
        else begin
            valid_in_pipeline[0] <= valid_in;
            data_in_pipeline[0] <= data_in;

            for (i = 1; i < SILU_PIPELINE_STAGES; i++) begin
                valid_in_pipeline[i] <= valid_in_pipeline[i - 1];
                data_in_pipeline[i] <= data_in_pipeline[i - 1];
            end
        end
    end

    // Calculate SiLU(x) = x * sigmoid(x)
    bf16_mul_single_cycle silu_mul (
        .op1(data_in_pipeline[SILU_PIPELINE_STAGES - 1]),
        .op2(sigmoid_out),
        .result(data_out),
        .isResultValid(),
        .isReady()
    );

    assign valid_out = valid_in_pipeline[SILU_PIPELINE_STAGES - 1];
endmodule