# Overview

This example draws a "rotozoomer" (rotating zoom in/out effect) on a VGA output, using the TinyFPGA BX.

## Prerequisites

You'll need to add a VGA output to your TinyFPGA.  The basic schematic used
can be found here: https://www.fpga4fun.com/PongGame.html

The default pins used by the example are:

| TinyFPGA BX pin | VGA pin | VGA signal |
|-----------------|---------|------------|
| 13 | 14 | VSYNC |
| 12 | 13 | HSYNC |
| 11 | 1 | RED |
| 10 | 2 | GREEN |
| 9 | 3 | BLUE |

(don't forget the 270ohm resistors in-line with the RGB pins).

## Principle of operation

Imagine a 2x2 texture array, indexed by (U,V).

```
 V
 ^
1| |X|
0|X| |
 +-----> U
  0 1
```

If we repeat this texture in all directions, we'll have something
that looks like a checkerboard.

It's pretty easy to see based on the diagram above that we want to draw a pixel whenever U=1 and V=1, or U=0 and V=0.

In order to scale and rotate this texture on to the screen, we
use some fixed-point trigonometry.

As we raster out the physical screen (640 X pixels, by 480 Y pixels), we also want to step across the texture, but we do so at an angle, and rate that are parameterised by time.

If we think about our (U,V) axis again:

```
 V
 ^
 |
 |
 |
 |
 |
 |
 +-----------------> U
```

.. and imagine that we want to step "1" unit at an angle of, say, 30 degrees.

```
 V
 ^
 |           
 |        
 |                .       
 |        1  .  ' |      
 |      . '       | v_step
 |  . '           |
 +'-'--------------> U
        u_step

```     

Based on the identity `SOH` `CAH` `TOA`, we have:

```
v_step = sin(30)
u_step = cos(30)
```

So the amount we need to add to the U value for every X step in VGA output space is `cos(30)`, and the amount we need to add to the V value is `sin(30)`.

.. and that's basically what we do.  Every time we take a step across the screen (ie. X value increments), we take a "step" through the texture space too (except at an angle).

If we want the texture to look a little larger, then we take smaller steps through the texture space (but in the same direction).  To make it smaller, we take larger steps.

If look at the code, we see three step:

* In each new frame, the increment values ​​of u and v are calculated (in fixed-point of 16 bits) according to the angle and scale (_u_stride_ and _v_stride_).
```Verilog
      prev_vsync <= vga_vsync;
      if (prev_vsync && !vga_vsync) begin
        ...
        u_stride <= (scale * unscaled_u_stride) >>> (16+3);
        v_stride <= (scale * unscaled_v_stride) >>> (16+3);
        ...
      end
```
* In each new line (xpos == 0) is recalculated the start values ​​of u and v (u_start and v_start, see figure).
```Verilog
        if (xpos == 0) begin
          u_start <= u_start - v_stride[16:0];
          v_start <= v_start + u_stride[16:0];
          u <= u_start;
          v <= v_start;
        end
```
* While we are increasing in x, we are not in the first position and the pixel is visible (videoactive == true), the values ​​of u and v are updated to obtain the color of the point in the texture (see calculation in the figure).
```Verilog
      if (video_active) begin
      ....
         if (xpos == 0) begin
            ...
         end
         else begin
            u <= u + u_stride[16:0];
            v <= v + v_stride[16:0];
         end
      end
```
![Giro.png](https://raw.githubusercontent.com/juanmard/tinyfpga-bx-demos/develop/examples/rotozoomer4/doc/Giro.png)

For the calculations, 16-bit fixed-point is used.
The _sine_ and _cosine_ tables are pre-calculated (in _256x16_0.16_sine_table.mem_) and are already in 16-bit fixed-point format.
For example, the calculation for a _**u**_ coordinate would be as follows:

Example of algorithm in decimal format with four decimals...

* cos(angle) -> 0.4011 -> change to fixed-point -> 0.4011 * 10000 = 4011 (0FAB save in table)
* Get from table and assign to **unscaled_u_stride** equal to **1·cos(angle)**
* Scale with another fixed-point 16bits format -> **scale * unscaled_u_stride**
* And returns to the decimal values, if for example scale is equal to 0.5 -> (5000 * 4011)/(10000 * 10000) = 0.20055 that it's equal to 0.5*0.4011 and assign to **u_stride** (divide by 2 it's shift to right one bit).

This value **u_stride** is used to increase the position **u**:
```Verilog
u <= u + u_stride;
```
In the binary bitmap of logo we have 80x96, so minimum 7 bits are needed [2<sup>6</sup>=64, it is not enough and 2<sup>7</sup>=128) to address both dimensions. After the calculations we take these 7 most significant bits (from 16 to 10) and discard the rest (decimals figures result of the operation) in this line of code:

```Verilog
    // get the bit texture image from memory.
    reg pixel;
    image image (.clk(pixel_clock), .x_img(u[16:10]), .y_img(v[16:10]), .pixel(pixel));

```
In this example we use a texture from **image.v** module with a logo of [_"FPGAwars group"_](https://groups.google.com/d/forum/fpga-wars-explorando-el-lado-libre) load from a **logo.list** file, from another project that you can find here: https://github.com/juanmard/screen-logo and in a discussion [here](https://groups.google.com/d/topic/fpga-wars-explorando-el-lado-libre/BvualDM5XCk/discussion).

In this example you can change the _"angle"_ and _"scale"_ with buttons conected from PIN_24 to PIN_21 with a switch and a resistor of 10KOhm.

![TinyFPGA-BX](https://raw.githubusercontent.com/juanmard/tinyfpga-bx-demos/develop/examples/rotozoomer4/doc/TinyFPGA-BX.jpg)

Easy! :)
