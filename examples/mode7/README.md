# Overview

This example aims to recreate something similar to "mode7" of the SNES (as popularised by games like Mario Kart).

The development was inspired by a conversation on the [TinyFPGA discourse site](https://discourse.tinyfpga.com), where Luke Valenty had spotted the rotozoomer and requested a tile based renderer.

## Prerequisites

You'll need to add a VGA output to your TinyFPGA.  The basic schematic used can be found here: https://www.fpga4fun.com/PongGame.html

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

The principle of operation for this is a little bit more complex than the rotozoomers..

In this case, we have a 64x64 map of tiles, each of which are 32x32 pixels.

We're projecting a view "frustrum" into the map/texture space.

```

VGA/screen space
================


    0 ____________________ 639
     |                    |
     |                    |  ^^ - sky
    a|--------------------|b <----- horizon
     |                    |  vv - ground
     |                    |
479 c`--------------------'d


```

The above represents what you would see on the screen.  The horizon is in the middle of the display.  We want to figure out where the points a,b,c and d lie in the texture space.

```

Map/Texture space
=================


 |              a              view
 |             /\            .  direction
 |            /  \      .
 |          c/    \ .
 |          .\  .  \
 |         .  \     \
 |        o - -`-----'
 |              d     b
 |
 +---------------------------
```

`o` represents the origin of the view frustrum triangle.

I'm taking a bit of a shortcut to figure out where a/b/c/d should be.

If `angle` points in the view direction, then `angle + (fov/2)`
points from the origin to `a`, and `angle - (fov/2)` points towards `b`.

To keep the math simple, I've made `c` and `d` a step of "4 units" from the origin, and `a` and `b` another "12 units" (16 total).  This allows the math to be done with the sine/cosine tables and simple shift operations.

Once we've calculated where `a`, `b`, `c` and `d` are in texture space, then it's a fairly simple matter of linearly interpolating between these points when rastering out the display.  As long as we're below the horizon.  Above the horizon we just display a plain cyan for the sky.

It may not be entirely clear from the code, but in order to divide the steps into 640 positions across the screen, I multiply the difference in X-coordinates by 102, then right-shift by 16 (divide by 65536).  102/65536 ~= 1/640, so this is a more efficient way of dividing by 640.  Similarly, 273/65536 ~= 1/240, so to scale the Y values we multiply by 273 and right-shift by 16.
