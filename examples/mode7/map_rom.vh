`ifndef __MAP_ROM__
`define __MAP_ROM__

module texture_rom(
  input clk,
  input [5:0] y_idx,
  input [5:0] x_idx,
  output reg [3:0] val);

  reg[3:0] TILEMAP_ROM[0:4095];  /* 64 x 64 x 4-bits per tile */
  initial $readmemh ("tile_map.mem", TILEMAP_ROM);

  always @(posedge clk) begin
    val <= TILEMAP_ROM[{y_idx, x_idx}];
  end

endmodule

`endif
