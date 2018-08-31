`ifndef __TEXTURE_ROM__
`define __TEXTURE_ROM__

module texture_rom(
  input clk,
  input [3:0] texture,
  input [4:0] y_idx,
  input [4:0] x_idx,
  output reg [3:0] val);

  reg[3:0] TEXTURE_ROM[0:16383];  /* 16 x (32 x 32 x 4bpp) textures */
  initial $readmemh ("textures.mem", TEXTURE_ROM);

  always @(posedge clk) begin
    val <= TEXTURE_ROM[{texture, y_idx, x_idx}];
  end

endmodule

`endif
