`ifndef __BITMAP_ROM__
`define __BITMAP_ROM__

module bitmap_rom(
  input clk,
  input [4:0] y_idx,
  input [4:0] x_idx,
  output reg [3:0] val);

  reg[3:0] BITMAP_ROM[0:1023];  /* 32 x 32 x 4bpp */
  initial $readmemh ("bitmap.mem", BITMAP_ROM);

  always @(posedge clk) begin
    val <= BITMAP_ROM[{y_idx, x_idx}];
  end

endmodule

`endif
