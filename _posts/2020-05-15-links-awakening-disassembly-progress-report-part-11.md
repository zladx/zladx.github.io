---
layout: post
title: "Link’s Awakening disassembly progress report – part 11"
lang: en
date: 2020-05-15 08:47
---

## ✨ New contributors

First let's congrats the following new contributors, who made their first commit to the project during the past months:

- [@Xkeeper0](https://github.com/Xkeeper0) did, in their own words, "Misc improvements across everything". This included a ton of things, including documenting debug tools and unused code, and a more readable way to format minimap data using clever macros.
- [@daid](https://github.com/daid) reverse-engineered the compression format used by background maps, and documented many memory locations.
- [@PileOfJunkMail](https://github.com/PileOfJunkMail) documented the signposts of the Prairie maze, Eagle's Tower wrecking ball, and replaced a lot of hardcoded numbers with constants.
- [@Vextrove](https://github.com/Vextrove), among other things, identified all the music tracks from the game, and added many constants to show their use throughout the code.

## 🔀 Source-code shiftability

Efforts to make the disassembled source code shiftable have been ongoing for half a year now. And this time, there's a great news:

**Zelda: Link's Awakening source code is now shiftable!** 🥳

What does that mean? Let's borrow an analogy from Revo, of the sm64decomp project:

> You have a piece of graph paper on a table, except there's a problem: nails are nailed through certain coordinates to the table. Try to move the paper and it tears it up.
>
> Shiftability means pulling each nail and writing down the coordinate it was pointing to.
>
> Binary modders are just really good at working with the nailed paper, regardless of the nails, by cutting and pasting available pieces and drawing on the empty spaces and stitching stuff (and in some cases just tapes on an extra piece of paper which is used as a dumping ground).

_For more details about shiftability, see the [previous disassembly progress report]({% post_url 2020-01-01-links-awakening-disassembly-progress-report-part-10 %})._

Getting the source code shiftable means that we reached the point where all nails are removed. Which means it is now much easier to add new code, or **change what the current code is doing–without breaking the game**. For instance, it could make it easier to create a level editor, a full-conversion mod, a gender-swapped version of the game, or a randomizer.

### Building tools to help pointers resolution

This was a months-long effort, that required scanning 150,000 lines of code for hardcoded pointers. To help this effort, some of it was automated.

ℹ️ _This section dives deeper into the technical details of pointers resolution. If you prefer a higher-level view, jump directly to the [next section](#ensuring-shiftability)._

Most pointers can't be reliably identified using purely automated ways: a series of bytes like `db $01, $4E, $87, $4F` could be the definition of two pointers (`$4E01` and `$4F87`), but might as well be a display list, or any data block.

However, **load instructions** (such as `ld hl, $65E2`) **almost always refer to a data pointer in the current bank**. This is not 100% foolproof: sometimes the loading instruction may be data that was wrongly interpreted as code, or it may be loading a pointer to be used later in another bank. But mostly, this is a good guess.

Using these guesses, a script scanning the source code for these loading instructions was written. Using the current state of the source code, and the symbols already identified, the script can output a list of missing data pointers for the current bank – including the length of the data block.

The way the script work is:

1. Read all the symbols already generated;
2. Read the given source file (e.g. `bank_1F.asm`);
3. Find all the ASM loading instructions in the source file that refer to a raw pointer (e.g. `ld hl, $65E2`);
3. Convert the raw pointers to data symbols in the current bank (e.g. `$652E` → `Data_01F_652E`);
4. Guess the size of the data blocks, by assuming the blocks runs up to the next symbol defined in the bank;
5. Emit a new set of debug symbols, augmented with the newly extracted pointers;
6. Run the disassembler again, feeding it the augmented symbols.

Once the disassembler is run again, it produces an updated version of the source file–but with the data blocks properly labeled, and with those labels correctly referenced the loading instructions.

This new source file must then be manually merged with the original source file, by cherry-picking the data-label changes, while keeping the annotated comments from the original files.

In the end, **this script helped to resolve around 50% of the raw data pointers**. The rest of it (jump tables, pointers tables, etc.) had to be labeled manually.

### Ensuring shiftability

If some hardcoded pointers remain in a code bank, adding or removing code from those banks won't shift those pointers. This could result in subtle bugs in the compiled game.

To ensure that a given code bank is shiftable, a simple check is to insert some `nop` instructions at the beginning of the bank (thus shifting the entire code by some amount), and play the game to see if anything breaks.

This method is simple–but running all code paths to ensure that everything works smoothly is difficult and time-consuming. Moreover, once a bug is found, it can be tedious to identify the precise location of the faulty pointer.

[@marijnvdwerf](https://github.com/marijnvdwerf) found a better way: **he used other versions of the game**. Three main different versions of Link's Awakening DX were released: v1.0, v1.1 and v1.2 (and this doesn't count smaller changes localized versions in English, French and German). While attempting to add support for other versions, Marijn found many small non-matching data blocks. Indeed, these data blocks contained raw pointers, that weren't properly shifted when compiling another version of the game.

Luckily, unmatched data blocks are easy to pinpoint–for instance using an hex diffing tool. The pointers still had to be fixed manually, but at least they were precisely identified.

### Caveats

Although the code is shiftable, some of the graphics data may not be moved around freely: it requires splitting large graphics sheets into several smaller pieces, which is not entirely done yet.

But shiftability is definitely a huge milestone, and should make the life of moders easier.

## 🎵 Music disassembling

Around March, [@Drenn1](https://drenn1.github.io/) started to have a look at the format of music tracks. Rather than documenting the code, he was attempting to understand the meaning of the music data.[^1]

[^1]: You may already know Drenn, because years ago he gave a new start to this project. He dived into all the numerous errors that had crept in the then-partial disassembled source code, and fixed them all. Moreover, he added a [checksum step](https://github.com/zladx/LADX-Disassembly/pull/2), to ensure the code would never diverge from the compiled game again.

    Drenn is also working on a fairly complete [disassembly of Zelda Oracle of Ages/Oracle of Seasons](https://drenn1.github.io/oracles-disasm/)–including a [level editor](https://github.com/Drenn1/LynnaLab) for these games. Check it out!

This led him to write [an impressive Python script](https://github.com/zladx/LADX-Disassembly/blob/master/tools/dump_music.py), that can read the music track binary data, and dump them in a human-readable form.

Long-story short, **a music track is defined by**:

1. A default transposition factor (usually 0);
2. A default speed;
3. Up to 4 channels tracks.

The 4 channels tracks are controlling the 4 hardware audio channels of the Game Boy: two square wave (that produces MIDI-like music), one programmable waveform (for playing custom sounds), and one programmable noise generator (for playing noise-based SFX).

And **each channel track is actually a program**. Channels tracks are a sequence of opcodes, that can either:

- Play a note,
- Pause,
- Change the sound volume,
- Change the speed,
- Loop for a number of times.

For instance, let's have a look at this channel track:

```m68k
ChannelDefinition_1b_50ab::
    set_envelope_duty $a0, $84, 2, 0
    notelen 4
    note A#3
    notelen 2
    rest
    note A#3
    note A#3
    notelen 1
    note A#3
    note A#3

    begin_loop $02
        notelen 6
        note A#3
        notelen 1
        note G#3
        notelen 3
        note A#3
        notelen 2
        rest
        note A#3
        note A#3
        notelen 1
        note A#3
        note A#3
    next_loop

    ; snip…
```

This channel track will produce the first 4 seconds of the main channel of the Title Screen theme, which you can hear below:

<audio controls>
  <source src="/videos/zelda-links-awakening-progress-report-11/ladx-title-screen.mp3" type="audio/mpeg">
  Your browser does not support the audio tag.
</audio>
_Link's Awakening – Title Screen_

Some opcodes are still not fully understood. Nonetheless, this is an incredible work, that allow us to both understand how the sound engine works, and how it can be modded to add new music tracks.

### Transposition and trivia

Interestingly, **only a handful of music tracks actually use a non-zero "default transpose factor"**:

- `MUSIC_HOUSE`, played inside the regular inhabitants houses (transposed by 4);
- `MUSIC_RICHARD_MANSION`, played inside Prince Richard's house (transposed by 4);
- `MUSIC_CUCCO_HOUSE`, played in the Hen House (transposed by 14, one octave);
- `MUSIC_MINIBOSS`, played during mini-boss battles (transposed by 2).

Except for the mini-boss, it seems that at some point during development the game designers decided to **make musics playing in several houses higher-pitched**. We can only guess why; but maybe that was to give a slightly more upbeat tone.

You can listen to the differences in `MUSIC_HOUSE` below:

<audio controls>
  <source src="/videos/zelda-links-awakening-progress-report-11/house-music-final.mp3" type="audio/mpeg">
  Your browser does not support the audio tag.
</audio>
_`HOUSE_MUSIC` – Final pitch as in the released game._

<audio controls>
  <source src="/videos/zelda-links-awakening-progress-report-11/house-music-original.mp3" type="audio/mpeg">
  Your browser does not support the audio tag.
</audio>
_`HOUSE_MUSIC` – Originally programmed pitch._

## 📦 Pre-composed save game

Did you know that Link's Awakening includes a pre-composed saved game, that gives you right from the start all inventory items, dungeons keys, special items, and so on?

It was included as a developers feature, and disabled in the released game. But with a bit of tweaking, it's easy to re-enable it. As Xkeeper and the fine people of [The Cutting Room Floor](https://tcrf.net/The_Legend_of_Zelda:_Link%27s_Awakening#Precomposed_Savegame) documented more than ten years ago, enabling the Debug tools of the game will automatically write this pre-composed saved game to the first slot.

So Xkeeper dug into the code, and found how this feature works: under some conditions, a segment of data is simply copied to the save slot.

Before they documented this block of data, it looked like this:

```m68k
label_4667::
    db 4, 1, 2, 3, 5, 6, 7, 8, 9, $A, $B, $C, 1, 1, 1, 0
    db 0, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2
    db 1, 1, 1, 1, 3, 1, 1, 1, 1, 4, 1, 1, 1, 1, 5, 1
    db 1, 1, 1, 6, 1, 1, 1, 1, 7, 1, 1, 1, 1, 8, 1, 1
    db 1, 1, 9
```

And after their work, and some bits of clever ASCII-art, the data for the pre-composed saved game now look like this:

```m68k
DebugSaveFileData::
    db INVENTORY_SHIELD          ; B button
    db INVENTORY_SWORD           ; A button
    db INVENTORY_BOMBS           ; Inventory slots
    db INVENTORY_POWER_BRACELET  ; .
    db INVENTORY_BOW             ; .
    db INVENTORY_HOOKSHOT        ; .
    db INVENTORY_MAGIC_ROD       ; .
    db INVENTORY_PEGASUS_BOOTS   ; .
    db INVENTORY_OCARINA         ; .
    db INVENTORY_ROCS_FEATHER    ; .
    db INVENTORY_SHOVEL          ; .
    db INVENTORY_MAGIC_POWDER    ; .

    db 1  ; Have Flippers
    db 1  ; Have Medicine
    db 1  ; Trading item = Yoshi doll
    db 0  ; 0 Secret Seashells
    db 0  ; (@TODO "Medicine count: found?")
    db 1  ; Have Tail Key
    db 1  ; Have Angler Key
    db 1  ; Have Face Key
    db 1  ; Have Bird Key
    db 0  ; 0 Golden Leaves / no Slime Key

    ; Dungeon flags ...
    ;  +-------------- Map
    ;  |  +----------- Compass
    ;  |  |  +-------- Owl Beak / Stone Tablet
    ;  |  |  |  +----- Nightmare Key
    ;  |  |  |  |  +-- Small keys
    ;  |  |  |  |  |
    db 1, 1, 1, 1, 1 ; Tail Cave
    db 1, 1, 1, 1, 2 ; Bottle Grotto
    db 1, 1, 1, 1, 3 ; Key Cavern
    db 1, 1, 1, 1, 4 ; Angler's Tunnel
    db 1, 1, 1, 1, 5 ; Catfish's Maw
    db 1, 1, 1, 1, 6 ; Face Shrine
    db 1, 1, 1, 1, 7 ; Eagle's Tower
    db 1, 1, 1, 1, 8 ; Turtle Rock
    db 1, 1, 1, 1, 9 ; POI: unused? (9th dungeon?)
```

Way easier to understand.

As you can see, two details are a little curious:

- An unused byte **displays a counter near the Medicine item**. It seems that at some point during the game development, the Medicine was intended to be a regular collectible item, and that the player could stash several of them in the inventory. This feature was cut from the released version of the game.
- Dungeons items are given for the 8 regular dungeons, **but also for a mysterious 9th dungeon**. It seems the game treats this dungeon as the Windfish Egg, but never actually uses these values. Maybe the Windfish Egg was intended to be a fully-featured 9th dungeon?

## 🗺 Minimaps format

Although the Overworld map is accessible all the time by pressing the SELECT button, dungeon minimaps are displayed in the inventory.

<span class="pixel-art gameboy-screen">
![Inventory displaying the Tail Cave minimap](/images/zelda-links-awakening-progress-report-11/cave-tail-minimap.png)
</span><br>
_The minimap of Tail Cave, the first dungeon._

To display those minimaps, the game stores one array of bytes per map. The `0xEF` value stands for a simple room, `0xED` for a room with a chest, and `0xEE` for the dungeon Nightmare room.

In the disassembled code source, these maps were previously formatted as a simple array of values:

```m68k
Minimap0::
    db   $7D, $7D, $7D, $7D, $7D, $7D, $7D, $7D
    db   $7D, $7D, $7D, $7D, $7D, $7D, $7D, $7D
    db   $7D, $7D, $7D, $7D, $7D, $7D, $EF, $7D
    db   $7D, $EF, $EF, $EF, $7D, $7D, $EE, $7D
    db   $ED, $7D, $EF, $ED, $EF, $ED, $EF, $7D
    db   $EF, $EF, $ED, $ED, $EF, $EF, $EF, $7D
    db   $EF, $7D, $EF, $ED, $ED, $7D, $7D, $7D
    db   $7D, $ED, $EF, $EF, $7D, $7D, $7D, $7D

Minimap1::
    db   $7D, $7D, $7D, $7D, $7D, $7D, $7D, $7D
    db   $7D, $ED, $ED, $ED, $EF, $EF, $EF, $7D
    db   $7D, $7D, $ED, $7D, $7D, $ED, $7D, $7D
    db   $7D, $EF, $EF, $7D, $7D, $EF, $EE, $7D
    db   $7D, $EF, $7D, $7D, $7D, $7D, $EF, $7D
    db   $7D, $ED, $7D, $7D, $7D, $7D, $EF, $7D
    db   $7D, $EF, $EF, $EF, $EF, $EF, $EF, $7D
    db   $7D, $7D, $ED, $ED, $ED, $ED, $7D, $7D
```

Xkeeper found a clever way to make this data more readable: using `rgbasm` charmaps.

In the source code, a `CHARMAP` command tells the assembler how to convert ASCII characters to sequences of bytes. This allow for instance to map the text of dialogs to the indices of the tile to use for each letter. Xkeeper found these charmaps another use: by **defining a custom charmap**, it becomes possible to format the dungeon minimap data as text and symbols.

```m68k
NEWCHARMAP MinimapCharmap
CHARMAP "  ", $7D   ; Blank (not shown on map)
CHARMAP "##", $EF   ; Room (shows up on map)
CHARMAP "Ch", $ED   ; Room with chest
CHARMAP "Nm", $EE   ; Nightmare boss marker
```

At compile-time, the charmap gets the text converted to the expected bytes. Which means that the dungeon minimap data now looks like this:

```m68k
    ;    0 1 2 3 4 5 6 7  - Minimap arrow positions.
Minimap0::
    db "                "
    db "                "
    db "            ##  "
    db "  ######    Nm  "
    db "Ch  ##Ch##Ch##  "
    db "####ChCh######  "
    db "##  ##ChCh      "
    db "  Ch####        "

Minimap1::
    db "                "
    db "  ChChCh######  "
    db "    Ch    Ch    "
    db "  ####    ##Nm  "
    db "  ##        ##  "
    db "  Ch        ##  "
    db "  ############  "
    db "    ChChChCh    "
```

Much more readable, and easier to edit.

Plus we can now clearly see the map of the first dungeon (Tail Cave) being shaped like a [Mini-Moldorm](https://zelda.gamepedia.com/Mini-Moldorm), and the second dungeon (Bottle Grotto) being shaped like the jar of the boss.

## What's next?

With source code shiftability achieved, the next point of focus is graphics data. For now the graphics of the game are not so easy to edit: many of them are laid out in a complicated way, using baroque color palettes. Some issues [have been opened](https://github.com/zladx/LADX-Disassembly/issues?q=is%3Aissue+is%3Aopen+sort%3Aupdated-desc+label%3Agraphics): hopefully we'll find a way to convert all graphics to easily editable sprite sheets, that can be transposed to the format expected by the engine at compile time.

Marijn is also close to merge an impressive PR that allows to build every single revision and language of the game.

And of course, the documentation of the physics engine and entities behavior is still an ongoing work.

---

### Notes
