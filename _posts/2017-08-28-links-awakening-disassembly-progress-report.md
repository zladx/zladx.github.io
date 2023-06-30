---
layout: post
title: "Link’s Awakening disassembly progress report – week 1"
author: kemenaran
lang: en
date: 2017-08-28 16:05
---

This week I found some time to work again of this [Zelda: Link's Awakening disassembly](https://github.com/zladx/LADX-Disassembly) project. And it got quite a few improvements done!

## Export all the graphics

The various graphics used in the game are stored in the ROM as binary files. Until recently, the binary sections containing the pictures weren’t even entirely identified.

This week, the remaining graphic banks were all mapped out, and all of them are now [exported as PNG files](https://github.com/zladx/LADX-Disassembly/tree/master/src/gfx). When compiling the game, the PNG files are converted back to their original [2bpp](http://www.huderlem.com/demos/gameboy2bpp.html) format, and inserted into the final binary.

For now, most of the pictures are exported as large sheets containing multiple graphical elements. For instance, this is a portion of the graphics sheet for the dungeons graphics.

<a class="pixel-art" href="https://github.com/mojobojo/LADX-Disassembly/blob/373f427f1722a781bd95b094b43a1683cf25d5da/src/gfx/world/dungeons.cgb.png">
![A portion of Link’s Awakening dungeons graphics](/images/zelda-links-awakening-progress-report/dungeons.png "This is how images are laid out in the game binary. Further manual work is needed to split them into individual items.")
</a>

Of course, it is possible to split these elements into individual items. But **for now only a minority some background tiles and sprites are split up** individually.

<span class="pixel-art">
[![Link’s Awakening title](/images/zelda-links-awakening-progress-report/intro-title.png "The title screen, in all its un-paletted glory.")](https://github.com/mojobojo/LADX-Disassembly/blob/373f427f1722a781bd95b094b43a1683cf25d5da/src/gfx/intro/title.cgb.png)
</span>
<span class="pixel-art">
[![Link’s Awakening palm trees](/images/zelda-links-awakening-progress-report/intro-palm-trees.png "These are the palm trees displayed behind Marin during the introduction sequence.")](https://github.com/mojobojo/LADX-Disassembly/blob/373f427f1722a781bd95b094b43a1683cf25d5da/src/gfx/intro/palm_trees.cgb.png)
</span>
<span class="pixel-art">
[![Link’s Awakening sea foam](/images/zelda-links-awakening-progress-report/intro-seafoam.png "The foam bathing Link’s feet during the introduction sequence.")](https://github.com/mojobojo/LADX-Disassembly/blob/373f427f1722a781bd95b094b43a1683cf25d5da/src/gfx/intro/seafoam.cgb.png)
</span>
<span class="pixel-art">
[![Link’s Awakening Windfish egg](/images/zelda-links-awakening-progress-report/intro-egg.png "The omnious Windfish egg displayed on the title screen. For some reason the top of the egg is stored at another location in the binary.")](https://github.com/mojobojo/LADX-Disassembly/blob/373f427f1722a781bd95b094b43a1683cf25d5da/src/gfx/intro/egg.cgb.png)
</span>

There is still work to do there.

You’ll also notice that **most of the graphics are actually stored twice**. Now remember that Zelda DX is actually a port on the Game Boy Color of the original “Zelda:Link’s Awakening”, which was initially released on the original monochrome Game Boy. However the remake could still run on the original Game Boy.

So it seems that during the development of the Game Boy Color remake, **Nintendo’s developers duplicated all the graphics**. This allowed them to tweak the graphics for the color edition—while leaving the original grayscale elements intact when running on a Game Boy or Game Boy Pocket.

You can see below some slight differences of graphics between the original graphics and colored ones.

<span class="pixel-art">
![Link’s Awakening overworld tiles](/images/zelda-links-awakening-progress-report/overworld-tiles.gif "Note how new Game Boy Color tiles were inserted over the chest graphics. The chest itself can be easily mirrored in-game, so no information is lost.")
</span>

_N.B. All graphics, colored or not, are stored as grayscale images. Color is applied at runtime, using external palette data. This is what allows an identical piece of graphics to get various colors, depending on the context it is used._

Although the gameplay and story of the remake were the same than in the  original game, some elements exclusive to the Game Boy Color were added. A notable one is the appearance of a **photographer**, which will sometime appear during the game to take a picture of Link’s adventures.

Good news: these pictures have been extracted too! However they are often compressed in some way. Space on a cartridge isn’t cheap, and was to be used with precaution. Also the photography scenes sometime contain moving parts and dynamic elements—which had to be encoded into the picture somehow.

This is why, although some of these pictures are recognizable, many of them look like garbled content, or a mixture of different items.

<span class="pixel-art">
[![First photo you obtain in the game](/images/zelda-links-awakening-progress-report/photo-nice-link.png "This photo seems to have been laid out and compressed manually (unlike other pictures which use a crude redundancy algorithm).")](https://github.com/mojobojo/LADX-Disassembly/blob/373f427f1722a781bd95b094b43a1683cf25d5da/src/gfx/photos/photo_nice_link.png)
</span>

## Memory locations now show in the debugger

Disassembling the game is mostly about making sense of a bunch of machine code. And one of the most used technique is to reconstruct the labels and comments of the source code.

One good thing about labeling the different parts of the disassembled code is that they’ll get exported into debug symbols. These debug symbols can be read by emulators, debuggers, and other different tools to give meaning to the game code. The more we label, the more we can use these labels to progress further.

But **until now, only function labels were exported into debug symbols**. But how about the memory location labels, which indicate how are used some specific part of the memory, and are almost as important as function labels? Well, due to the way they were labeled in the disassembly, memory labels were not exported at all.

This week the declaration of the memory labels was rewritten, so that they get exported into the debug symbols. Which means for instance that **memory locations now show up in the debugger!** This will definitely make reverse-engineering easier in the future.

![BGB debugger without the memory location labels](/images/zelda-links-awakening-progress-report/bgb-without-wram-labels.png "We've got function labels. But what about those raw memory addresses sprinkled around?")
![BGB debugger with the memory location labels](/images/zelda-links-awakening-progress-report/bgb-with-wram-labels.png "Now this is better: variable names instead of raw addresses.")

## Awake decompiler

A few years ago, Github user [@devdri](https://github.com/devdri) started working on a tool to help the Game Boy games disassembling efforts : a **custom Game Boy decompiler** named [awake](https://github.com/devdri/awake).

The idea is to present the game code into a nice user interface, which allows browsing the code and jumping back and forth easily. It also features many heuristics to make sense of the assembly code: detecting the start and end of procedures, exposing jump tables, and displaying the assembly code as high-level C-style expressions.

Although this project hasn’t been active for the past few years, it seems it could be quite useful on its own. A few missing features would be a nice improvement to this tool though.

So this week I added support for [labeling functions and memory locations from the UI](https://github.com/kemenaran/awake/pull/1). Support for importing debug symbols is also coming soon. Hopefully this will make `awake` a worthwhile tool for understanding the disassembled code.

![Screenshot of the awake Game Boy disassembler](/images/zelda-links-awakening-progress-report/awake-game-boy-disassembler.png "The conversion of assembly to C-style expressions makes it easier to understand the code. At least to me.")

## Disassembling guides

It's not easy to jump into a new project. How is the game even compiled? Do I need a custom toolchain? What are the tools used to explore the code and graphics?

Fortunately **some guides are now included in the project [README file](https://github.com/mojobojo/LADX-Disassembly/blob/master/README.md)**. You'll get a quick overview on how to use a debugger to label code, and how the scripts used to extract the graphics data work.

## What’s next

For the next weeks I would like to:

- Use `awake` to label some code, and see how it could be improved ;
- Start splitting up the main assembly file (`bank0.asm`) into separate files ;
- Label more of the introduction sequence code ;
- Start using [pokemon-reverse-engineering-tools](https://github.com/pret/pokemon-reverse-engineering-tools) instead of custom python scripts.

And we’ll see how it goes.
