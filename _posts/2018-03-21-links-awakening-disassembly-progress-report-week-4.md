---
layout: post
title: "Link’s Awakening disassembly progress report – week 4"
author: kemenaran
lang: en
date: 2018-03-21 11:30
---

After a six-month pause, disassembling efforts have resumed again! And quite a lot got done this week.

## [Dump the game’s dialogs](https://github.com/mojobojo/LADX-Disassembly/pull/30)

Back to December, a surprise contribution arrived from [Sanqui](https://github.com/Sanqui). He submitted a pull request containing a clean dump of all the game’s dialogs.

Sanqui even [explained](https://github.com/mojobojo/LADX-Disassembly/issues/31#issuecomment-365180230) how he extracted the dialog’s texts and indexing table from the ROM:

> I found the text in the intro ("What a relief!"), set a breakpoint on it, and traced back the relevant code to figure out where the pointer table is. From there I was ready to write a script to dump all the text. :)

He may make it simpler than it sound though: the [Python script he wrote](https://github.com/mojobojo/LADX-Disassembly/blob/103286a66a323fc60f66b888d0571fa4b455b762/scripts/text.py) is quite a piece of work, and can extract all the dialogs in a readable format.

Anyway you can now browse through the game’s dialog, from Marin’s iconic [opening lines](https://github.com/mojobojo/LADX-Disassembly/blob/103286a66a323fc60f66b888d0571fa4b455b762/src/text/dialog.asm#L10-L22) to the texts added [specifically for the DX version](https://github.com/mojobojo/LADX-Disassembly/blob/103286a66a323fc60f66b888d0571fa4b455b762/src/text/dialog_dx.asm).

<span class="pixel-art gameboy-screen">
![Link's Awakening First dialog lines](/images/zelda-links-awakening-progress-report-4/first-dialog.png)
</span>

_There is a lot going on to display these letters on screen._

## [Figure out how the dialog system works](https://github.com/mojobojo/LADX-Disassembly/pull/35)

Beside dumping the dialog’s data, Sanqui also reverse-engineered how the game actually prints a dialog on-screen.

As many things in the game, the dialog system is driven by a state-machine, [dispatching the execution](https://github.com/mojobojo/LADX-Disassembly/blob/6d1b56e4d96b4b5572899b9e1d7013b556dd8183/src/code/home/dialogs.asm#L39-L55) according to all the states the dialog can be in.

```asm
; Values for wDialogState
DIALOG_CLOSED              equ $00
DIALOG_OPENING_1           equ $01
DIALOG_OPENING_2           equ $02
DIALOG_OPENING_3           equ $03
DIALOG_OPENING_4           equ $04
DIALOG_OPENING_5           equ $05
DIALOG_LETTER_IN_1         equ $06
DIALOG_LETTER_IN_2         equ $07
DIALOG_LETTER_IN_3         equ $08
DIALOG_BREAK               equ $09 ; press A to continue
DIALOG_SCROLLING_1         equ $0A
DIALOG_SCROLLING_2         equ $0B
DIALOG_END                 equ $0C ; press A to close
DIALOG_CHOICE              equ $0D ; press A to choose
DIALOG_CLOSING_1           equ $0E
DIALOG_CLOSING_2           equ $0F
```

The dialog system takes advantage of an interesting data-transfert system used throughout the game. It allows a function to define an asynchronous data request to update the Video Background data. During the next vertical-blank, this request will be executed by the VBlank handler, which will display the next letter of the dialog’s text.

Also, if you played the game, you probably remember how it is possible to steal one of the items from Mabe’s Village shop.

<span class="pixel-art gameboy-screen" style="width:316px">
![Animation of Link stealing an item in the shop](/images/zelda-links-awakening-progress-report-4/stealing-in-shop.gif "“I wasn’t kidding when I said pay! Now, you’ll pay the ultimate price!!”")

_I wouldn’t advise going back to this shop again._

If you actually do this, your save file will be renamed to “THIEF” – without any way to change it back.

Well, turns out this behavior has been slightly obfuscated: in the code, the characters string `"THIEF"` is actually stored as `'T'+1, 'H'+1, 'I'+1, 'E'+1, 'F'+1`. Which means that for ROM hackers looking at the data, all that will appear is `"UIJFG"`, and no thief to be found.

## [Add disassembly for bank 2](https://github.com/mojobojo/LADX-Disassembly/pull/37)

For a long time, extracting the resources of the game (pictures, dialogs) made good progress–but disassembling the code kind of stalled.

The thing is, only some portions of the code are extracted yet (let alone labelled and documented). And it became more and more difficult to disassemble a new bank. Existing disassemblers were not good enough to produce a workable output, and often lacked the ability to use existing labelled symbols when disassembling a new bank.

I tried for many hours to fix the [Python-based disassembler](https://github.com/pret/pokemon-reverse-engineering-tools/blob/master/pokemontools/gbz80disasm.py) used for the [Pokemon Blue/Red disassembly](https://github.com/pret/pokered), but I found the code hard to edit and prone to unwanted changes when adding new features.

Fortunately, no more than two months ago, [mattcurie](https://github.com/mattcurrie) released a new [Game Boy disassembler, mgbdis](https://github.com/mattcurrie/mgbdis), also written in Python. It already took advantages of symbol files to disassemble new banks, and I found it relatively easy to fix some minor issues, edit the output style, and add new features.

After spending some hours tweaking the output, a new bank was finally committed: we have the [code for bank 2](https://github.com/mojobojo/LADX-Disassembly/tree/master/src/code/bank2.asm)! This bank contains some part of the audio engine, plus gameplay-related code.

Of course much of it still remains to be documented. But the logic for [selecting the music track to be played](https://github.com/mojobojo/LADX-Disassembly/blob/c0395fec70dbc0f7df27bd9d2400dda8672f5968/src/code/audio/music.asm#L31) on the overworld has already been pretty well documented; you can check it out.

[![Code sample with the Overworld music data](/images/zelda-links-awakening-progress-report-4/overworld-music-tracks.png)](https://github.com/mojobojo/LADX-Disassembly/blob/c0395fec70dbc0f7df27bd9d2400dda8672f5968/src/code/audio/music.asm)

_These values map the Overworld. Can you recognize the Mysterious Forest on the left ($04), and the Tal Tal Mountain Range ($06) on the top?_

## What’s next

Now that the disassembler can produce high-quality output, before reverse-engineering more code, I would like to add disassemblies for the other banks. The trick is to identify which sections are code and which are data–but at least for some of these banks it should be relatively easy to figure it out.
