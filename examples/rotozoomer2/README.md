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

The principle of operation here is the same as in rotozoomer1, but in this
case we're actually using a bitmap image (from bitmap.mem) rather than a
checkerboard pattern.
