# Overview

This example aims to recreate something similar to "mode7" of the SNES (as popularised by games like Mario Kart).

The development was inspired by a conversation on the [TinyFPGA discourse site](https://discourse.tinyfpga.com), where Luke Valenty had spotted the rotozoomer and requested a tile based renderer.

The difference between this example, and the other "mode7" example is that this one uses a 64x64 tile map, where
each tile can be one of 64 8x8 textures.  This offers a more flexibility than the 16 32x32 sized textures used in the
original.  A downside of this approach is that the map is smaller, and uses more memory.

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

The principle of operation is the same as for the other mode7 example, except
in this case we have a 64x64 map of tiles, each of which are 8x8 pixels.

The textures and tile map source data are included in the "resources" folder,
along with a README.md file that explains how to use them.
