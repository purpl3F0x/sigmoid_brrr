`default_nettype none

module bf16_abs (
    input wire [15:0] op1,
    output logic [15:0] result
);
    always_comb begin
        result = {1'b0, op1[14:0]};
    end
endmodule