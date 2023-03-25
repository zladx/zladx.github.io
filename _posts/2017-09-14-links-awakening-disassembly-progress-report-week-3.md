---
layout: post
title: "Link’s Awakening disassembly progress report – week 3"
lang: en
date: 2017-09-14 16:21
---

This week didn’t get as much work done as the previous week—but it sure has some progress.

## [Export all labels to the debug symbols.](https://github.com/zladx/LADX-Disassembly/pull/25)

`rgbasm` has special rules for deciding whether or not a label should be exported to the debug symbols. By default, only global labels (that are visibles by all code units) are exported into the `.sym` file.

This makes us face an annoying choice when labeling code. The best way to label intermediary routines would be to use *scoped labels*, which are prefixed with a dot, like `.some_label`. Scoped labels hey don’t leak into the global namespace, and there can be several of them with the same name (as long as they are not in the same scope). But in this case, these labels won’t get exported to the debug symbols, and won’t show up in our disassembling tools.

To work around this, we had to resort to an annoying fix: make most of the labels globals, like `SomeLabel::`. But then we loose the locality of the label, and all of them have to be unique in the whole source of the game.

Fortunately, the contributors who maintain the [rgbds](https://github.com/rednex/rgbds) toolchain recently added an option to export all labels to the debug symbols, regardless of the label visibility. **We can now have our cake and eat it: use local labels, and still having them visible in the debugger.** Liberal use of local labels makes the disassembly much more readable, and I’m quite happy to have this technical restriction lifted.

![BGB screenshot showing all labels in the disassembly code](/images/zelda-links-awakening-progress-report-3/bgb-all-labels.gif)

_Having all labels displayed in the debugger makes the disassembly much more readable._

## [Label the File Save dialog routines.](https://github.com/mojobojo/LADX-Disassembly/pull/27)

The code for the File Save dialog is located right at the start of bank1. As this is code I often stumble upon when opening this file, I was keep to label at least the general structure of it.

As many other places in the code, it uses a [jump table](https://github.com/kemenaran/LADX-Disassembly/blob/b22c9a138aac248fffd275880526f94ec73aa94b/src/code/bank1.asm#L8-L17) to control the transition between the Overworld and the File Save dialog.

<span class="pixel-art gameboy-screen">
![Link's Awakening File Save dialog](/images/zelda-links-awakening-progress-report-3/file-save-dialog.png "I wonder which location is supposed to be represented by this brick wall…")
</span>

## [Label more of the render loop](https://github.com/mojobojo/LADX-Disassembly/pull/28)

For one year I’ve been writing the draft for an article that details the structure of the game’s main render loop. Unfortunately some bits and pieces of this section of the code are still obscure to me.

This week I tried to **fill the gaps in areas I don’t understand yet**. And a lot of progress has been made, especially on the transition special effets.

During the rendering, **several types of special effects can affect the background**, and give it a wavy feeling. Initially I though there were only three effects:

- `0x01`: The dream shrine transition,
- `0x02`: The teleport departure effect when playing Manbo’s Mambo,
- `0x03`: The teleport arrival effect when being teleported to Manbo’s Pond.

But it turns out other transitions are using this code! They actually count in reverse around zero:

- `0xFE`: The slow up-and-down motion when on the fisherman boat,
- `0xFF`: The wavy transition when the Wind Fish appears.

Unlike the first three transitions, these one are **interactive**: instead of the same frozen frame being displayed while the transition effect is playing, during interactive transitions the game continues rendering frames—which makes it possible to move Link while the special effect is applied, for instance.

<span class="pixel-art gameboy-screen" style="width:316px">
![The Wind Fish apparition](/images/zelda-links-awakening-progress-report-3/windfish.gif)
</span>

_Without this interactive effect, the Wind Fish apparition wouldn't be as impressive._

## What’s next

At some point I’d like to finally complete this article about the main render loop structure. There are still a few lines of mystery, but it’s almost there!
