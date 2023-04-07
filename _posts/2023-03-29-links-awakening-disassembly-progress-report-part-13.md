---
layout: post
title: Link's Awakening Disassembly Progress Report – part 13
date: 2021-02-20T06:39:01.436Z
lang: en
---

After a solid two-years hiatus, here's a new progress report for the Zelda: Link’s Awakening disassembly! Here we’ll
cover the changes that happened in the past two years.

## New contributors

First let's congratulate the following new contributors, who made their first commit to the project during the past two years:

- [@samuel-flynn](https://github.com/samuel-flynn) labeled a [couple of global variables](https://github.com/zladx/LADX-Disassembly/pull/182) related to the rupees buffer.
- [@Nog-Frog](https://github.com/Nog-Frog) noticed that a graphics file included both credits graphics and the photographer sprites, and [split it in two](https://github.com/zladx/LADX-Disassembly/pull/353).
- [@squircledev](https://github.com/squircledev) fixed a gallicism by [renaming "Cyclop key" to "Slime key"](https://github.com/zladx/LADX-Disassembly/pull/402).
- [@tobiasvl](https://github.com/tobiasvl) added support for [compiling the project using RGBDS 0.6](https://github.com/zladx/LADX-Disassembly/pull/451) – and then opened 33 others PR to fix comments, document physics, bosses, and much more.
- [@ISSOtm](https://github.com/ISSOtm) [fixed an non-indexed image](https://github.com/zladx/LADX-Disassembly/pull/454), which was breaking compatibility with RGBDS 0.6.
- [@KelseyHigham](https://github.com/KelseyHigham) decoded all color palettes data to readable RGB values, and added speaker labels to dialogs.

## New blog

This series of articles moved to a new blog! Instead of being hosted on kemenaran's personnal blog, interleaved with other content, they are now published on this dedidated web site. Of course, the former URLs now redirect to these new pages.

This move will make it easier for readers to subscribe to this website for new articles. I hope it will also encourage a more collaborative process for getting these articles out.

The [sources of this site](https://github.com/zladx/zladx.github.io) are public! So if you notice a typo or something, feel free to submit a PR. Contributing right from Github's UI usually works well, without the need to fork and run the website locally.

## Palettes documentation (RGB macros and all)

The biggest addition of Link's Awakening DX, compared to the original monochrome version, is of course color.

![](/images/zelda-links-awakening-progress-report-13/in-game-palettes.png)<br>
_Example of the color palette used for green objects, and for Link's sprite._

But this wasn't reflected in the disassembly until now. Color palettes were represented in a binary format, matching the underlying hardware, but difficult to read and edit by humans.

```asm
ObjectPalettes::
    ds  $FF, $47, $00, $00, $A2, $22, $FF, $46
```
_The same palette, as it was appearing in the source code._

Kelsey Higham wanted colors that were easier to read. After a bit of collective macro writing on the Discord server, the final format ends up like this:

```asm
ObjectPalettes::
    rgb   #F8F888, #000000, #10A840, #F8B888
```

There's a hairy chunk of macro code to convert an #RGB color to a two-bytes GBC color, at compile time. But the result is very pleasant to read: hexdecimal RGB colors are used everywhere, especially on the web, and many color editors can import and export from this format.

https://github.com/zladx/LADX-Disassembly/pull/465

Then Kelsey Higham started the daunting task of converting _all color palettes_ of the game to this format. Quite a task – but the end result is worth is: as far as we know, all color palettes in the source code are now decoded.

But the #RGB format has another advantage: as it is so widely used, many text editors can display the described color right in the editor itself.

Look at the result:

<img alt="A screenshot of the source code opened in a text editor, with the rgb colors being appropriately colored" width="320" src="/images/zelda-links-awakening-progress-report-13/rgb-palettes.png"/><br>
_Visual representation of the game palettes in VS Code._

That's a really easy way to see the content of a palette, right from the source code.

## BG encoder fixes

https://github.com/zladx/LADX-Disassembly/pull/398, https://github.com/zladx/LADX-Disassembly/pull/456

## RAM shiftability

https://github.com/zladx/LADX-Disassembly/issues/409

## Spriteslots

https://github.com/zladx/LADX-Disassembly/pull/335/files, https://github.com/zladx/LADX-Disassembly/wiki/Game-engine-documentation#4-entities

## Split entities

https://github.com/zladx/LADX-Disassembly/pull/431 and more

## Peeophole replacement

https://github.com/zladx/LADX-Disassembly/pull/347

## Dialog lines

https://github.com/zladx/LADX-Disassembly/pull/509

## rgbds 0.6

https://github.com/zladx/LADX-Disassembly/pull/451

## Windfish interactive disassembler

https://github.com/jverkoey/windfish/

## Rom hacks

- Translations
- Randomizer (+ monthly hacks)
- Turbo Français
- tobiasvl redux?

