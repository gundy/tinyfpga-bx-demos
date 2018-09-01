/*
 * Rotozoomer example.
 *
 * This example draws a "rotozoomer" (rotating zoom in/out effect) on
 * a VGA output.
 *
 * Principle of operation:
 *
 * Imagine a 2x2 texture array, indexed by (u,v).
 *
 * As we raster out the physical screen (640 X pixels, by 480 Y pixels),
 * we also step across the texture, but we do so at an angle, and rate
 * that are parameterised by time.
 *
 */

`define __COMMON_CODE_ROOT_FOLDER "../.."
`include "../../hdl/core.vh"
`include "sine_table.vh"
`include "cosine_table.vh"

// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input PIN_24,
    input PIN_23,
    input PIN_22,
    input PIN_21,
    input CLK,     // 16MHz clock
    output USBPU,  // USB pull-up resistor
    output PIN_9,
    output PIN_10,
    output PIN_11,
    output PIN_12,
    output PIN_13);

    // drive USB pull-up resistor to '0' to disable USB
    assign USBPU = 0;

    wire vga_vsync, vga_hsync, vga_red, vga_green, vga_blue;
    assign PIN_13 = vga_vsync;
    assign PIN_12 = vga_hsync;
    assign PIN_11 = vga_red;
    assign PIN_10 = vga_green;
    assign PIN_9 = vga_blue;

    wire inc_angle, dec_angle, inc_zoom, dec_zoom;
    assign inc_angle = PIN_24;
    assign dec_angle = PIN_23;
    assign inc_zoom  = PIN_22;
    assign dec_zoom  = PIN_21;

    wire pixel_clock;
    reg[9:0] xpos;
    reg[9:0] ypos;
    wire video_active;

    reg [8:0] angle = 0;                 /* angle that image is rotated (0..255) */
    signed reg [15:0] scale = 16'h8001;         /* scale to draw at */

    localparam ROTATE_CENTRE_X = 320;
    localparam ROTATE_CENTRE_Y = 240;

    signed reg [15:0] unscaled_u_stride;
    signed reg [15:0] unscaled_v_stride;

    signed reg [32:0] u_stride;
    signed reg [32:0] v_stride;

    // todo check widths etc
    signed reg [32:0] u_offset;
    signed reg [32:0] v_offset;

    // start positions for u&v at the beginning of each line
    signed reg [16:0] u_start;
    signed reg [16:0] v_start;

    // current positions for u&v (fixed point 1.16 indexes into the texture space)
    signed reg [16:0] u;
    signed reg [16:0] v;

    VGASyncGen vga_generator(.clk(CLK), .hsync(vga_hsync), .vsync(vga_vsync), .x_px(xpos), .y_px(ypos), .activevideo(video_active), .px_clk(pixel_clock));

    sine_table y_angle_table(.clk(pixel_clock), .idx(angle[7:0]), .val(unscaled_v_stride));
    cosine_table x_angle_table(.clk(pixel_clock), .idx(angle[7:0]), .val(unscaled_u_stride));

    // get the bit texture image from memory.
    reg pixel;
    image image (.clk(pixel_clock), .x_img({3'b0,~u[16:10]}), .y_img({3'b0,v[16:10]}), .pixel(pixel));

    reg prev_vsync;

    always @(posedge pixel_clock)
    begin
      prev_vsync <= vga_vsync;
      if (prev_vsync && !vga_vsync) begin
        // vsync has been brought low; we're in the vertical blanking period;
        // update per-frame animation values
        if (inc_angle) angle <= angle + 1;
        if (dec_angle) angle <= angle - 1;
        if (inc_zoom) scale <= scale + 50;
        if (dec_zoom) scale <= scale - 50;
        u_stride <= (scale * unscaled_u_stride) >>> (16+5);
        v_stride <= (scale * unscaled_v_stride) >>> (16+5);  // 16 to account for scale, 5 to make textures bigger
        u_offset <= (ROTATE_CENTRE_X * unscaled_u_stride) >>> (16+5);
        v_offset <= (ROTATE_CENTRE_Y * unscaled_v_stride) >>> (16+5);
        u_start <= -u_offset[16:0];
        v_start <= v_offset[16:0];
      end
      if (video_active) begin
        if (xpos == 0) begin
          u_start <= u_start + v_stride[16:0];
          v_start <= v_start - u_stride[16:0];
          u <= u_start;
          v <= v_start;
        end else begin
          u <= u + u_stride[16:0];
          v <= v + v_stride[16:0];
          if (pixel)
            vga_green <= 1'b1;
          else
            vga_green <= 1'b0;
        end
      end else begin
        vga_blue  <= 1'b0;
        vga_green <= 1'b0;
        vga_red   <= 1'b0;
      end
    end

endmodule
