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

## Fixes to the tilemaps encoder

### A primer on tilemaps

To display large pictures or sceneries, Link's Awakening DX uses tilemaps (like almost all Game Boy games do). Tilemaps store the indices of tiles in a large array, and can be easily displayed by the hardware.

Except that Link's Awakening DX doesn't use raw tilemaps, but somehow compresses them. Instead of a linear sequence of tile indices, the game stores what we call _Draw Commands_. These little chunk of data instruct the decoder to _"paint"_ the tilemap with a specific tile.

This hand-written compression helps to reduce the size of the tilemaps. For instance, if a tilemap is mostly black, but with a tiny patch of repeated details in the middle, the game can simply instruct to paint a row or a column of detailed tiles, and ignore the rest of the tilemap (which will use the background color).

_To read more on encoded tilemaps, see [the relevant entry](/posts/links-awakening-disassembly-progress-report-part-12#-decoding-the-tilemaps) in a previous progress report._

### The issue with some tilemaps

User `@Javs` on Discord reported an issue occurring when editing the tilemap of the File creation menu. When decoding, editing and then re-encoding this specific tilemap, the tile indicating the save slot number would disappear.

![file creation screenshots](/images/zelda-links-awakening-progress-report-13/tilemap-broken-file-select.png)<br>
_On the left, the original version. On the right, the edited version, lacking the save slot number._

Now why did that happen? Turns out a combination of different issues.

### Investigating a weird bug

The first thing we tried was to disassemble the relevant code.

When displaying this specific screen, there are two loading stages before the screen becomes interactive:

1. The game requests the BG map to be filled with black tiles during the next vblank,
2. Then the game simultaneously:

    1. requests the file creation tilemap (and attrmap) to be loaded during the next vblank,

    2. and requests a specific tile to be written to the BG map during the next vblank: the save slot index.

So far, so good. Now why doesn't this work anymore when the tilemap has been edited?

A possible cause of troubles is that Link's Awakening tilemaps use a custom compression format, where repeated tiles can be "painted" over the screen. And most of the time, these compressed tilemaps were handwritten. So when we decode and re-encode a tilemap, there's always a difference in how the compression is expressed (because the automatic encoding program doesn't make the same choices than the original artists). In the end, the re-encoded tilemap is supposed to be functionaly equivalent.

But could the different encoding trigger some underlying issues, like a race condition? What if the original encoding wrote to the top of the screen first, but the new re-encoding wrote to the top of the screen last, overwriting the changes made manually to the BG map?

Turns out the issue was simpler than that.

To save space, the original tilemaps often don't encode the bytes for the background color. Instead they first fill the whole BG map with black (or white) tiles, then "paint" the tilemap over this background color. This is precisely what the File creation BG tilemap does: it only paints the bricks and letters, not the black areas.

![File creation screen + overlay](/images/zelda-links-awakening-progress-report-13/tilemap-original.png)<br>
_The original tilemap only draws the tiles different from the background color._

When decoding the tilemap, we want the result to be editable using an external tool. So the decoder does the same steps: filling the background with a default color, and then painting over. Which means the background color gets included into the decoded tilemap.

But when re-encoding the tilemap, the background color was also imported into the file. Which resulted in the tilemap containing draw commands for all the black background areas.

![File creation screen edited + overlay](/images/zelda-links-awakening-progress-report-13/tilemap-reencoded.png)<br>
_But an edited tilemap used to define draw commands for the whole screen._

This is not only wasteful, it also means that the game paints the tilemap bytes twice: once when filling the Background with the default color, and once again when reading the tilemap.

And that was our issue: the game filled the background with black, then wrote the tile for the save slot number and painted the tilemap. As the save slot number is written over a black tile, it wasn't overwritten by the original tilemap. But it was by the re-encoded version.

### The fix

In theory, fixing the issue was easy: we just had to ignore the background color when re-encoding the BG map.

That said, the actual fix took some evenings. The encoder didn't had any proper compression scheme implemented (all bytes were always written sequentially), but to allow some bytes to be skipped, a proper implementation of writing only to certain regions was needed. This also uncovered several bugs in the decoder part, which had to be solved.

### All done

In the end:
- Decoding an original BG tilemap or attrmap is more reliable, and produces better results;
- Encoding a decoded tilemap ignores filler bytes, which fixes the issue with the File creation screen;
- The encoded tilemaps are now even smaller than the original hand-tuned ones.

And there's our fixed version in-game:

![unknown-1](/images/zelda-links-awakening-progress-report-13/tilemap-fixed.png)<br>
_The edited File creation tilemap, with the save slot number correctly displayed._

A remaining caveat is that, for now, the background color has to be specified manually, both when decoding and encoding the tilemap. For instance:

```shell
# Decoding
tools/convert_background.py decode src/data/backgrounds/menu_file_creation.tilemap.encoded --filler 0x7E --outfile src/data/backgrounds/menu_file_creation.tilemap
# Editing using an external tool
# …
# Re-encoding
tools/convert_background.py encode src/data/backgrounds/menu_file_creation.tilemap --filler 0x7E --outfile src/data/backgrounds/menu_file_creation.tilemap.encoded
```

But hopefully this is something that can be defined by the file name at some point.

## RAM shiftability

The disassembled code has been shiftable for quite a while now. That means it is possible to add or remove some code, build the game, and have things still working: all pointer addresses that used to be hardcoded now resolve to the new locations automatically.

But at the beginning of 2022, there were still issues with the RAM shiftability: adding, removing or moving some variables in memory would break various things in the game.

Now, after a [good number of fixes](https://github.com/zladx/LADX-Disassembly/issues/409), the RAM is now properly shiftable.

For instance, you can add a block of 5 bytes at the beginning of the RAM definitions (thus shifting all RAM addresses by 5), and the game will still work properly. Or, to free up some space, a developer may choose to move a big block of RAM data out of RAM bank 0 to another RAM bank: this is expected to work without too much work.

All of this makes extensive ROM hacks possible: for instance, theoretically, it opens the gates to increase the maximum number of entities, or the number of letters reserved for the player's name.

## Split entities

Entities are the various NPCs, enemies, and actors that form the dynamic elements of the game. The game has more than 200 of these entities, and they make up a good part of the entire game code.

In the original source code, we have good reasons to believe that the entities code was grouped in a handful of source files.

<pre>
./entities
├── entities3.asm
├── entities4.asm
├── entities5.asm
├── entities6.asm
├── entities7.asm
├── entities15.asm
└── entities18.asm
└── entities19.asm
└── entities36.asm
</pre>
_How the original code was probably structured._

But to make the code easier to browse and to understand, the disassembly attempts to split the code of each entity into its own source file.

<pre>
./entities
├── 03__helpers.asm
├── 03_arrow.asm
├── 03_bomb.asm
├── 03_droppable_fairy.asm
├── 03_hookshot_hit.asm
├── 03_liftable_rock.asm
├── 03_moblin.asm
├── 03_octorok.asm
└── …
</pre>
_How the disassembly attempts to split the entities each into their own file._

These split are not straightforward: the entities code are not cleanly isolated, but instead reference a kind-of-standard set of helper functions, duplicated into each original file. Sometime an entity will even use some code from another entity in the same file!

So this is still very much a work in progress: at least one file needs to be split, and the files structure is not final yet. But it progresses steadily.

## Sprite-slots documentation

Daid took some time to research and document the ways entities sprites are defined and loaded on each room transition.

As the Game Boy video memory is quite limited, management of graphical resources is quite important. As for the NPC sprites, the games had a few challenges:
- When a room is initially loaded, how are loaded the required sprites for the room's entities?
- And when transitioning from a room to another, how to ensure that the sprites of the appearing entities will be loaded _while the sprites of the disappearing entities are still there_?
- How does the code of an entity knows _where in memory_ its sprites have been loaded?
- And what about NPCs or enemies that uses more sprites than usual? Does the standard loading mechanism still work?
- How does this interact with following NPCs (Marin, Bow-Wow, etc.), which also uses sprite memory?

After a lot of researches, this ended up in [a large PR documenting the sprite-slots mechanism](https://github.com/zladx/LADX-Disassembly/pull/335), and a [higher-level wiki article](https://github.com/zladx/LADX-Disassembly/wiki/Game-engine-documentation#4-entities) on this topic. 

To summarize the key points of the sprites resource management:

- At any point in the main gameplay, there are 4 slots available in VRAM, corresponding to 4 entity spritesheets.
- Each room defines four associated spritesheet-ids. When transitioning from one room to another, the game engine compares the spritesheets currently loaded in VRAM with the spritesheets requested by the new room, and marks the non-loaded-yet ones as needing to be copied.
- Rooms can only load **two new spritesheets**. This ensures that during room transitions both the two previous shrite-sheets _and_ the two new ones will be available.
- However, when warping directly to a new room, **all four spritesheets** are loaded at once. This allows to load larger NPCs or enemies, by putting them behind a warp (like a staircase).
- The position of each spritesheet is hardcoded: entities expect their sprites to be always loaded at the same location (excepting special cases). Which means entities can conflit which each other: for instance, Octorocks and Moblins can never be displayed in the same room, as they both expect their spritesheet to be loaded at the same location.

That's the gist of it – but of course there's more.

For a more detailed read on this topic, and details about how the following NPCs interact with this system, head to the [sprite-sheets article on the wiki](https://github.com/zladx/LADX-Disassembly/wiki/Game-engine-documentation#4-entities)!

## Peephole replacement

Often, in the code, we need to turn a numerical value into a constant. 

For instance, there may be a lot of patterns like this:

```asm
ld   a, $08               ; load the constant "08" into register a
ldh  [hMusicTrack], a    ; write the content of a to the variable hMusicTrack
```

There may be dozens of similar uses of `hMusicTrack` in the code.

At some point, someones may identify the meaning of all these numerical values:

```asm
MUSIC_NONE                              equ $00 
MUSIC_TITLE_SCREEN                      equ $01 
MUSIC_MINIGAME                          equ $02 
MUSIC_GAME_OVER                         equ $03
MUSIC_MABE_VILLAGE                      equ $04
MUSIC_OVERWORLD                         equ $05
MUSIC_TAL_TAL_RANGE                     equ $06
MUSIC_SHOP                              equ $07
MUSIC_RAFT_RIDE_RAPIDS                  equ $08
MUSIC_MYSTERIOUS_FOREST                 equ $09
…
```

Good! But it now means that we need to look up all usages of hMusicTrack, and manually replace the numerical value by the proper constant. Tedious.

Luckily, `@daid` [wrote a generic tool](https://github.com/zladx/LADX-Disassembly/pull/347) to make this task easier: the _peephole replacer_.

This tool can read a list of constants, a code pattern to look for — and then scan the whole code for this specific pattern.

In our case, we can use the peephole replacer with the following declaration:

```python
PeepholeRule("""
    ld   a, $@@
    ldh  [hMusicTrack], a
""", read_enum("constants/sfx.asm", "MUSIC_"))
```

Now invoking `./tools/peephole-replace.py` will detect all uses of `hMusicTrack` in the code, and automatically replace the numerical value with the proper constant.

```asm
ld   a, MUSIC_RAFT_RIDE_RAPIDS              
ldh  [hMusicTrack], a    
```

Of course this has been used with many other constants as well (sound effects, entity flag, etc.). The peephole replacer can even perform more complex operations, like expanding the values of bitflags:

```asm
; Before
ld   hl, wEntitiesOptions1Table               
add  hl, bc                                  
ld   [hl], $D0

; After
ld   hl, wEntitiesOptions1Table               
add  hl, bc                                  
ld   [hl], ENTITY_OPT1_IS_BOSS|ENTITY_OPT1_SWORD_CLINK_OFF|ENTITY_OPT1_IMMUNE_WATER_PIT
```

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
