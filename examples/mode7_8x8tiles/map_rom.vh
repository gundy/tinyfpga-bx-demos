`ifndef __MAP_ROM__
`define __MAP_ROM__

module map_rom(
  input clk,
  input [5:0] y_idx, /* 0..63 */
  input [5:0] x_idx, /* 0..63 */
  output reg [5:0] val);

  reg[5:0] TILEMAP_ROM[0:4096];  /* 64x64 x 6-bits per tile */
  initial $readmemh ("tile_map.mem", TILEMAP_ROM);

  always @(posedge clk) begin
    val <= TILEMAP_ROM[{y_idx, x_idx}];
  end

endmodule

`endif
