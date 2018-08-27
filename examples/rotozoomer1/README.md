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

Of course, in this simple case, there is no "texture" - only a simple equality check, `out_pixel = (U==1&&V=1)||(U=0&&V=0)`, as per above.

To get the rotozoomer effect, we change the angle every frame, and based on the angle we also choose a scale factor.

Easy! :)
