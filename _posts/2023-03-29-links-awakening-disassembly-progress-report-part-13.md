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

## Palettes documentation (RGB macros and all)

https://github.com/zladx/LADX-Disassembly/pull/465

<img alt="A screenshot of the source code opened in a text editor, with the rgb colors being appropriately colored" width="320" src="/images/zelda-links-awakening-progress-report-13/rgb-palettes.png"/><br>
_Visual representation of the game palettes in VS Code._

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

