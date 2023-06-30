---
layout: post
title: "Link’s Awakening disassembly progress report – week 6"
author: kemenaran
lang: en
date: 2019-08-29 19:00
---

These “weekly” reports are more like monthly now, and will probably be renamed at some point. But work continues! Let’s see what interesting happened in the past weeks.

## Making the disassembly stand-alone

An ongoing effort is to make the disassembly standalone. For now, the disassembled files covers only around 80% of the ROM. The remaining blanks are filled at compile-time using the original ROM.

This is not optimal. It means that a copy of the original game is still needed to compile the disassembly. Also some parts of the code jumps to functions that are not referenced in the disassembly yet.

Making the disassembly standalone requires **adding those missing and less figured out banks**. And this is [what is being done](https://github.com/zladx/LADX-Disassembly/issues/42) now, starting with the audio code.

## Audio code and data

The audio in the game is split in several banks; each one covering a specific kind of audio effect:

- Full-length music tracks and jingles (using a combination of square-waves);
- Waveform-based sound effects;
- Noise-based sound effects.

The code and data for playing these audio effects was missing from the ROM–until now. This month, **a basic disassembly was added for banks containing the audio code** ; that is banks `0x1B`, `Ox1E` and `0x1F`. The code now lies in the [`src/code/audio/`](https://github.com/zladx/LADX-Disassembly/tree/master/src/code/audio) directory.

This is a good progress towards understanding more of the audio formats. However the disassembly is still very rough: it has only very few labels and comments–and **the music data format has not been figured out yet**. This allows to fill blanks in the project for now; but much more work is waiting.

## Credits

Continuing the “making the disassembly standalone” project, another bank was added this month: the code and data responsible for the **ending sequence and credits**. And there are a few tidbits of interest in it.

For instance, it seems that **the staff roll code was written way before the other parts of the credits sequence**. The staff roll code and data is laid out at the beginning of the bank–even the code that switches to the different parts of the ending sequence comes after.

This is unusual: most of the time the entry point of the bank is near the beginning of the bank, and the dispatch table for the different states comes quickly after.

<span style="display:block; max-width:300px">
![Link's Awakening – layout of bank 17](/images/zelda-links-awakening-progress-report-6/bank-17-layout.png)
</span>

Was the credits code written before the ending sequence was designed? Or is it a relic from “For the frogs the bell tolls”, the game whose code was used as the basis of Link’s Awakening engine?

---

Another interesting find is **the way the staff names are displayed** during the credits roll.

<span class="pixel-art gameboy-screen">
![Link's Awakening Staff Roll](/images/zelda-links-awakening-progress-report-6/Final-render.png)
</span>

**First, how is this nice transparency effect done?** The Game Boy doesn't have dedicated graphics functions to display full transparency, blending the foreground with the background.

So a hardware trick is used throughout the game: it relies on the LCD screen latency. When a game object needs to have some transparency (like shadows or ghosts), it is only displayed every other frame. As the individual pixels on the screen have some latency, the final color that the screen displays to the player is a mix between the foreground and the background color–thus providing the transparency effect.

**But why was transparency used here?** Although it showcases a visual effect uncommon and difficult to achieve on this console, it also makes the end result is not very readable.

The thing is, **the developers had to**.

Remember, the Game Boy has three ways to display graphics on screen: a tiled background, a window overlapping the background, and sprites. Here the tiled background is already used to display the clouds and the see. And the window   is always opaque–it can't be configured to show the background image underneath. So **the letters need to be displayed using sprites**. Sprites can have one color of transparency, and show the background underneath, so this is all fine.

Except for one thing. **At most 10 sprites can be displayed** on a single line. Due to a hardware limitation, aligning more than 10 sprites on the same horizontal line will result in a nasty uncontrollable flicker. And some names will clearly use more than 10 letters, and thus more than 10 sprites. The letters would flicker like crazy.

So what do developers usually did back then? A common technique is to avoid displaying all the sprites on a same line at once. For instance by, you guessed it, displaying some of the sprites only on even frames–and the others only on odd frames.

And this is exactly what Link's Awakening developers did. The staff roll actually looks like this:

<span class="pixel-art gameboy-screen">
![Link's Awakening Staff Roll - Even frames](/images/zelda-links-awakening-progress-report-6/Frame-even.png)
</span>

<span class="pixel-art gameboy-screen">
![Link's Awakening Staff Roll - Odd frames](/images/zelda-links-awakening-progress-report-6/Frame-odd.png)
</span>

Clever? Yes.<br>
Readable? Not so much.<br>
Unavoidable? Definitely.

## Contribution activity

Since last month there's been a lot more discussions on the [Discord server](https://discord.gg/sSHrwdB) of the project. People much more knowledgeable than me about Zelda DX and disassembling things chimed in–coming from the pret discussion group, the Zelda speedrun community, and the Zelda 4 randomiser chat.

I'm really happy about having discussions with other people about this project, other disassembling efforts, and more. For instance, `@featherless` used an experimental tracing disassembler of them – to produce a relatively high-level disassembly of the ROM that automatically sorts out code from data.

Also this month, to give an easier time to newcomers, the [README file](https://github.com/zladx/LADX-Disassembly) has been streamlined, new [wiki guides](https://github.com/zladx/LADX-Disassembly/wiki) were written, and others were completed.

## Automated checks

And, of course, **say hello to our new continuous integration bot!** This bot will tell you, for each PR, wether the code still compiles, and check that it still produces a 1:1 reproduction of the original ROM.

Setting up a compilation toolchain in the cloud wasn't that easy (I'm looking at you, Docker). But it was worth it: since it was set up, the automated checks already caught a mistake of mine.

<img alt="Github automated version check passing" src="/images/zelda-links-awakening-progress-report-6/green-checks.png" width="485"/><br>
_Isn't that green checkmark lovely?_

## What's next?

My short-term goal is still to make the disassembly stand-alone in a relatively short time.

But there is more to do. For instance, [the entities data could be better parsed](https://github.com/zladx/LADX-Disassembly/issues/94). And more exciting, all the entities IA code is just [sitting here](https://github.com/zladx/LADX-Disassembly/issues/80), waiting to be indexed. Ever wanted to know how was implemented the behavior of your favorite Zelda enemy? Now is the chance to figure it out.
