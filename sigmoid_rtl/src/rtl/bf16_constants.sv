package bf16_constants;
  localparam logic [15:0] ONE = 16'h3F80;
  localparam logic [15:0] TWO = 16'h4000;
  localparam logic [15:0] THREE = 16'h4040;
  localparam logic [15:0] FOUR = 16'h4080;
  localparam logic [15:0] FIVE = 16'h40A0;
  localparam logic [15:0] SIX = 16'h40C0;

  // Largest value below 1
  localparam logic [15:0] ALMOST_ONE = 16'h3F7F; // 0.99609375
  localparam logic [15:0] ONE_POINT_FIVE = 16'h3FC0;

  localparam logic [15:0] MINUS_ONE = 16'h8000 | ONE;
  localparam logic [15:0] MINUS_TWO = 16'h8000 | TWO;
  localparam logic [15:0] MINUS_THREE = 16'h8000 | THREE;
  localparam logic [15:0] MINUS_FOUR = 16'h8000 | FOUR;
  localparam logic [15:0] MINUS_FIVE = 16'h8000 | FIVE;
  localparam logic [15:0] MINUS_SIX = 16'h8000 | SIX;
endpackage : bf16_constants