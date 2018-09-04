`ifndef __ONE_OVER_N__
`define __ONE_OVER_N__

// module that uses a lookup table to calculate 1.0/n
// results are in 0.16 unsigned fixed-point format.
module one_over_n(
  input clk,
  input [7:0] n,
  output reg signed [16:0] result);

  reg[15:0] LOOKUP_TABLE[0:255];
  initial $readmemh ("one_over_n.mem", LOOKUP_TABLE);

  always @(posedge clk) begin
    result <= { 1'b0, LOOKUP_TABLE[n] };
  end

endmodule

`endif
