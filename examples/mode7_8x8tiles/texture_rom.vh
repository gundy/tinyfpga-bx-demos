`ifndef __TEXTURE_ROM__
`define __TEXTURE_ROM__

module texture_rom(
  input clk,
  input [5:0] texture_idx,
  input [2:0] y_idx,
  input [2:0] x_idx,
  output reg [3:0] val);

  reg[3:0] TEXTURE_ROM[0:4095];  /* 16 x (32 x 32 x 4bpp) textures */
  initial $readmemh ("textures.mem", TEXTURE_ROM);

  // the indexing below is a little bit complicated, but is because our
  // texture image is 64x64 pixels, split into 8x8 textures.  I'm fairly
  // confident the math works out. :D
  always @(posedge clk) begin
    val <= TEXTURE_ROM[{ texture_idx[5:3], y_idx, texture_idx[2:0], x_idx }];
  end

endmodule

`endif
