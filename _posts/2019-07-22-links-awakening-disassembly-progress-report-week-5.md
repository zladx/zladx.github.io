---
layout: post
title: "Link’s Awakening disassembly progress report – week 5"
lang: en
date: 2019-07-24 08:00
---

It’s been a while! The [last disassembly progress report](/posts/links-awakening-disassembly-progress-report-week-4) was published more than one year ago. Meanwhile, what happened?

Well, kind of a slowdown, actually. But a few weeks ago, with the release of Link’s Awakening remake on the Switch drawing nearer, the disassembling efforts gained some steam again.

Which means many things appeared! Let’s see what’s new.

## New repository

In 2015, on the 11th of August, [mojobojo](https://github.com/mojobojo/) started a disassembly project. Four years later, this project has grown tremendously. With the participation of [several external contributors](https://github.com/zladx/LADX-Disassembly/blob/master/README.md#contributors), it made little sense to still have the repository under a single user account.

Thankfully, mojobojo agreed to **transfer the admin rights to an organization**. Which means the repository has a new home! It is now reachable at [github.com/zladx/LADX-Disassembly](https://github.com/zladx/LADX-Disassembly).

The new organization makes also possible to add many admins and many contributors, which could make the contributions smoother.

## More maps

Many of Link's Awakening ROM hacks feature new maps. Throughout the years, many level editors came and went, trying to figure out how to read the game maps, and how to insert modified maps back without breaking the ROM.

<span class="pixel-art" style="display: block; max-width: 400px">
[![Zelda Link’s Awakening entire Overworld](/images/zelda-links-awakening-progress-report-5/zelda-dx-overworld.jpg)](/images/zelda-links-awakening-progress-report-5/zelda-dx-overworld.jpg)
</span>
_Isn’t that beautiful?_

Unfortunately **there is no central documentation about the map data format**. Informations are scattered here and there, deep in the code of the level editors.

So with the help of [Xkeeper0](https://github.com/Xkeeper0), a [new parser for the maps, rooms, objects and warp points](https://github.com/zladx/LADX-Disassembly/blob/master/tools/map_parser.py) was written in Python. This parser emits nicely formatted files containing the rooms table and objects.

In the end, the format is easy enough:

- Maps are 16x16 arrays of pointers to rooms;
- Rooms are variable-length objects, containing:
    - A two-bytes header describing the room tileset and floor template,
    - A variable number of objects.

---

**The neat thing is the objects format**.

To save space on the original cartridge, rooms are not stored as a sequential array of all the rooms' blocks (which would always use 10 × 8 bytes per room).

Instead, **rooms are painted**.

First, a configurable ground tile is repeated on the whole room.

<span class="pixel-art">
![room-1](/images/zelda-links-awakening-progress-report-5/room-1.png)
</span>

Then, in dungeons, as the walls of most rooms look the same, a room template is applied.

<span class="pixel-art">
![room-2](/images/zelda-links-awakening-progress-report-5/room-2.png)
</span>

And afterwards, objects are laid out individually on the room, in single-blocks – or in strips spanning several blocks.

<span class="pixel-art">
![room-3](/images/zelda-links-awakening-progress-report-5/room-3.png)
</span>

<span class="pixel-art">
![room-4](/images/zelda-links-awakening-progress-report-5/room-4.png)
</span>

<span class="pixel-art">
![room-5](/images/zelda-links-awakening-progress-report-5/room-5.png)
</span>

<span class="pixel-art">
![room-6](/images/zelda-links-awakening-progress-report-5/room-6.png)
</span>

In the end, here is how the final room looks like, after it has been entirely painted with objects.

<span class="pixel-art">
![room-final](/images/zelda-links-awakening-progress-report-5/room-final.png)
</span>

The final size for this: **only 30 bytes** (instead of 80 bytes if all objects had to be stored individually). Neat. The game even defines a few macros which can paint directly a whole house or tree, for instance.

This also allows for nice animations of the rooms being constructed. You can even see the designers changing their minds mid-development, and overlapping bushes with flowers.

<span class="pixel-art">
![An animated version of an overworld room being constructed](/images/zelda-links-awakening-progress-report-5/room-painted.gif)
</span><br>
_Credits: XKeeper0 [Link’s Awakening Depot](https://xkeeper.net/hacking/linksawakening/)_

## More code

Last year, around 3 banks of code had been disassembled. Today, we are at 9 banks of code disassembled–and counting.

**Disassembling new banks used to be difficult**. The disassembler spew lot of invalid code, that had to be fixed by hand, and the existing variables and functions were not carried to the newly disassembled code.

This changed with the use of mattcurie’s [mgbdis](https://github.com/mattcurrie/mgbdis) new disassembler, which emits very good quality code.

But **disassembling a bank is useless if we don’t do anything with it**. Once we have the raw code, it is only useful after cutting some noise: separate data from the actual code, and cross-referencing it with the existing banks. All of this takes time–so new banks are added progressively.

Recently, banks 14 and 20 were added. They contain some inventory code, the code responsible for applying room templates when loading a dungeon’s room, overworld audio tasks, palette effects…

… and something interesting: the code for enemies, NPC, dungeon bosses and entities behavior. Reverse-engineering the bosses IA will be fun.

## More audio

The game uses the Game Boy audio capabilities for good effect: it may simultaneously play a long music track, a short jingle, and very short sound-effect.

<span class="pixel-art gameboy-screen">
![A screenshot of Marin singing](/images/zelda-links-awakening-progress-report-5/Marin singing.png)
</span><br>
_I know you can hear the music in your head._

For a long time, the disassembly labelled two variables to control the sound effect:

```coffee
; Play an audio effect immediately
hSFX::      ds 1 ; FFF3

; Play an audio effect next
hNextSFX::  ds 1 ; FFF4
```

Put the identifier of a sound effect in `hSFX`, and it will immediately. Put it in `hNextSFX`, and it will play after the current sound effect is finished.

Easy, right?

Well, while I was disassembling the code for the overworld audio tasks performed on each frame, I noticed **the identifiers between these two variables didn’t match**. For instance, writing `$04` in `hSFX` would play a beeping `SFX_LOW_HEARTS` sound effect; but writing the same value in `hSFX` would play a “The doors of the room are now open” sound effect. Hmm.

I dug into the code to find where `hNextSFX` was eventually written into `hSFX`. I couldn’t find such code. Something was wrong.

Now, audio is not my speciality. So I turned to the Game Boy hardware documentation. Turns out that the Game Boy can generate a wide variety of audio (in stereo, for good mesure): it has two square-wave outputs, one waveform output, and one configurable noise generator.

Oh. Of course.

The reason two sound effects can sound different is that there are actually **two kind of sound-effects**: wave-based, and noise-based. It all comes to the hardware capabilities.

Everything makes much more sense:

- **Jingles** are square-wave-based sound effects. They sound like the music: a sequence of _beeps_;
- **Wave sound effects** are based on a wave-table. Although they are way larger to store, they can output a greater variety of sounds;
- **Noise sound effects** use the configurable noise generator to produce _swings_, _swooshs_, _scratches_ and _rumbles_.

Now I could fix the code:

```coffee
; Play a waveform-based audio effect immediately
hWaveSFX::   ds 1 ; FFF3

; Play a noise-based audio effect immediately
hNoiseSFX::  ds 1 ; FFF4
```

In hindsight this is quite obvious, and probably well-known by ROM hackers. But well, this was my epiphany. At least we now have a growing but already decent [list of the different sound effects](https://github.com/zladx/LADX-Disassembly/blob/master/src/constants/sfx.asm).

## And now?

Two days ago, while trying to understand the entities data format, it occurred to me: **this project is now closer to its completion than from its beginning**. Maps, tiles and dialogs are dumped, most banks are disassembled, around half of the code is at least partially documented. And with all the data already labelled, the second half should be much easier.

Of course there are tons of things still to be done. Tilesets, warp data and chest data are missing. The room formats could be much improved. The enemy IA is in view, but still will require efforts. Audio has only been lightly touched.

But **it has never been easier to make progress**. Gone are the days of erring in a pile of assembly instructions, having no clue of what the code is doing: there is always a labelled variable to give a hint.
