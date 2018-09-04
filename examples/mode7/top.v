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
`include "texture_rom.vh"
`include "map_rom.vh"
`include "one_over_n.vh"

// look in pins.pcf for all the pin names on the TinyFPGA BX board
module top (
    input CLK,    // 16MHz clock
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

    wire pixel_clock;
    reg[9:0] xpos;
    reg[9:0] ypos;
    wire video_active;
    wire is_sky;

    assign is_sky = ypos < 240;

    reg [9:0] angle;    /* angle that image is rotated (0..255) */
    signed reg [15:0] scale;   /* scale to draw at */

    localparam ROTATE_CENTRE_X = 320;
    localparam ROTATE_CENTRE_Y = 240;
    localparam FIELD_OF_VIEW_DEGREES = 90;

    // 256 BRADs (binary radians) = 360 degrees = 2*PI radians
    localparam [7:0] FIELD_OF_VIEW_BRADS = $rtoi((FIELD_OF_VIEW_DEGREES/360.0)*256.0);


    // co-ordinates in map/texture space of top-left (a), top-right (b),
    // bottom-left (c), and bottom-right (d) screen position.  When rendering
    // the screen we interpolate between these co-ordinates.
    // map is 64 blocks across (6-bits)
    // texture is 32 pixels across (5 bits)
    // 6+5+ 16 bits fractional component = 11+16 = 27 bits
    signed reg [28:0] origin_u;
    signed reg [28:0] origin_v;
    signed reg [28:0] a_u;
    signed reg [28:0] a_v;
    signed reg [28:0] b_u;
    signed reg [28:0] b_v;
    signed reg [28:0] c_u;
    signed reg [28:0] c_v;
    signed reg [28:0] d_u;
    signed reg [28:0] d_v;

    signed reg [35:0] left_u;
    signed reg [35:0] left_v;
    signed reg [35:0] right_u;
    signed reg [35:0] right_v;

    signed reg [15:0] unscaled_u_stride_left;
    signed reg [15:0] unscaled_v_stride_left;
    signed reg [15:0] unscaled_u_stride_right;
    signed reg [15:0] unscaled_v_stride_right;

    signed reg [32:0] u_stride;
    signed reg [32:0] v_stride;

    // current positions for u&v (fixed point 1.16 indexes into the texture space)
    signed reg [32:0] u;
    signed reg [32:0] v;

    VGASyncGen vga_generator(.clk(CLK), .hsync(vga_hsync), .vsync(vga_vsync), .x_px(xpos), .y_px(ypos), .activevideo(video_active), .px_clk(pixel_clock));

    // view frustrum left side
    sine_table vf_left_y_angle_table(.clk(pixel_clock), .idx(angle[9:2] + (FIELD_OF_VIEW_BRADS/2)), .val(unscaled_v_stride_left));
    cosine_table vf_left_x_angle_table(.clk(pixel_clock), .idx(angle[9:2] + (FIELD_OF_VIEW_BRADS/2)), .val(unscaled_u_stride_left));

    // view frustrum right
    sine_table vf_right_y_angle_table(.clk(pixel_clock), .idx(angle[9:2] - (FIELD_OF_VIEW_BRADS/2)), .val(unscaled_v_stride_right));
    cosine_table vf_right_x_angle_table(.clk(pixel_clock), .idx(angle[9:2] - (FIELD_OF_VIEW_BRADS/2)), .val(unscaled_u_stride_right));

    // u,v = 26,25,24,23,22,21 <= map position, 20,19,18,17,16 <= texture position
    wire [3:0] texture_idx;
    map_rom map(.clk(pixel_clock), .x_idx(u[26:21]), .y_idx(v[26:21]), .val(texture_idx));

    reg [3:0] rom_rgb;
    texture_rom texture(.clk(pixel_clock), .texture_idx(texture_idx), .y_idx(v[20:16]), .x_idx(u[20:16]), .val(rom_rgb));

    wire signed [9:0] y_minus_240;
    assign y_minus_240 = ypos - 9'sd240;

    signed reg [16:0] one_over_y;  // 1.0 / (y-240) (in 0.16 format)
    one_over_n one_over_y_table(.clk(pixel_clock), .n(y_minus_240[7:0]), .result(one_over_y));

    assign vga_red = video_active && (!is_sky && rom_rgb[0]);
    assign vga_green = video_active && (is_sky || (!is_sky && rom_rgb[1]));
    assign vga_blue = video_active && (is_sky || (!is_sky && rom_rgb[2]));

    // assign vga_red = video_active && one_over_y[8];
    // assign vga_green = video_active && one_over_y[7];
    // assign vga_blue = video_active && one_over_y[6];


    initial begin
        origin_u <= {8'd13, 5'd0, 16'd0};
        origin_v <= {8'd23, 5'd0, 16'd0};
    end

    reg prev_vsync;

    always @(posedge pixel_clock)
    begin
      prev_vsync <= vga_vsync;
      if (prev_vsync && !vga_vsync) begin
        angle <= angle + 1;
        // vsync has been brought low; we're in the vertical blanking period;
        // update per-frame animation values
        // calculate top-left, top-right, bottom-left and bottom-right
        // view frustrum locations in texture-space
        a_u <= origin_u + (unscaled_u_stride_left <<< (12));
        a_v <= origin_v + (unscaled_v_stride_left <<< (12));
        b_u <= origin_u + (unscaled_u_stride_right <<< (12));
        b_v <= origin_v + (unscaled_v_stride_right <<< (12));

        c_u <= origin_u + (unscaled_u_stride_left <<< (3));
        c_v <= origin_v + (unscaled_v_stride_left <<< (3));
        d_u <= origin_u + (unscaled_u_stride_right <<< (3));
        d_v <= origin_v + (unscaled_v_stride_right <<< (3));
      end

      if (video_active && (ypos >= 240)) begin
          case (xpos)
            10'd0: begin
              u <= left_u;
              v <= left_v;
              // calculate step to get from left->right
              u_stride <= ((right_u - left_u) * 8'sd102) >>> 16;
              v_stride <= ((right_v - left_v) * 8'sd102) >>> 16;
            end
            10'd639: begin
              // calculate new left right positions in texture-space for the next scanline
              left_u <= c_u + (((a_u - c_u)>>>16) * one_over_y);
              left_v <= c_v + (((a_v - c_v)>>>16) * one_over_y);
              right_u <= d_u + (((b_u - d_u)>>>16) * one_over_y);
              right_v <= d_v + (((b_v - d_v)>>>16) * one_over_y);
            end
            default: begin
              u <= u + u_stride;
              v <= v + v_stride;
            end
          endcase
      end
    end

endmodule
