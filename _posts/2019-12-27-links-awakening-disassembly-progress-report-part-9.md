---
layout: post
title: "Link’s Awakening disassembly progress report – part 9"
lang: en
date: 2019-12-27 08:56
---

## New contributors

Since the last report, the following people made first-time contributions to the [disassembling project](https://github.com/zladx/LADX-Disassembly):

-  [marijnvdwerf](https://github.com/marijnvdwerf) documented more of the Super Game Boy code, and sorted out the data used by SGB commands (read more below). Thanks!

## Super Game Boy frame

First, let’s expand a little on `@marijnvdwerf`'s improvements to the Super Game Boy code.

The Super Game Boy (a device that allowed to [play Game Boy cartridges on a Super NES](https://en.wikipedia.org/wiki/Super_Game_Boy)) has many features games could use – including custom color palettes, custom audio, or multiplayer support. But   Zelda: Link’s Awakening included support only for the more prominent SGB feature: a custom border surrounding the display when playing the game.

![Zelda Link’s Awakening being played on the Super Game Boy, including the SGB custom frame.](/images/zelda-links-awakening-progress-report-9/sgb-frame.gif)

### Sending the frame

Like all SNES or Game Boy graphics, the custom frame is made of tiles. Practically, this requires tiles data describing the tile graphics, a tilemap describing how the tiles are laid out, and some color palettes.

Now, as the Super GameBoy was created _after_ the release of the original Game Boy, the Game Boy doesn't know about this device. Specifically, it doesn't have a specific communication channel with external hardware.

So, how can a Game Boy communicate with another device that was released as an afterthought? Well, the method eventually chosen was to **abuse an existing hardware port**. To communicate with a Super GameBoy, a game must _write to_ the joypad registers. Of course, the joypad registers are usually read-only (a game can't press a hardware button by itself). But when running on a Super GameBoy, the joypad hardware registers become also writable, and are used to send data to the device.

Using this communication method, uploading a custom frame involves a [series of steps](https://github.com/zladx/LADX-Disassembly/blob/master/src/code/super_gameboy.asm#L56-L130) to communicate with the Super GameBoy:

1. Send a `MLT_REQ` command to **switch to 2-players mode** (this will confirm the game is running on a Super GameBoy);
2. Send a `MASK_EN` command to **make the displayed screen black** while the game will be messing with <abbr title="Video RAM">VRAM</abbr>;
3. **Copy the tiles data** for the custom frame from the ROM to the Game Boy VRAM;
4. Send a `CHR_TRN` command to **upload the VRAM content** to the Super GameBoy;
5. **Upload the tilemap and palettes** for the custom frame from the ROM to the Game Boy VRAM;
6. Send a `PCT_TRN` command to **upload the VRAM content** to the Super GameBoy;
7. Send a `MASK_EN` command to finally **make the displayed screen visible again**.

### Timing the transfers

Each of these transfers takes some time. The usual way to wait for the transfers to be completed would be to sync on the v-blank intervals, occurring every 16,6 ms. **But during these operations, the screen is off, so no v-blank occurs**.

Instead, the code uses carefully crafted busy-loops to execute a specific number of instructions. Once all the instructions are executed, the game knows the right amount of time must have passed, and the transfer should be complete.

### Extra background

While documenting the Super GameBoy code, data and commands, `@marijnvdwerf` found that the tilemap for the custom frame includes a bit of content that is never visible in-game.

<span>
<img style="width: 512px" alt="Zelda Link’s Awakening Super GameBoy frame as coded in the ROM, with extra content visible" src="/images/zelda-links-awakening-progress-report-9/sgb-frame-full.png"/><br>
_Only the content inside the red square is visible during normal gameplay; the rest of the frame is clipped._
</span>

Why this extra image section was left in the game is still to be discovered.

## Using the Zelda III disassembly to fill out entities data

Game using an entity system tend to store entity attributes in a not-so-straightforward way. Instead of declaring an array of entities, game often use several arrays of attributes, indexed by entity.

```c
// An array of entity structs would be the idiomatic way
// to declare entities in C.
struct entity = { int x, int y, int health /*, … */ };
struct entity entities[MAX_ENTITIES];

// But in games, entities are more often stored
// as arrays of entity attributes.
int entitiesX[MAX_ENTITIES];
int entitiesX[MAX_ENTITIES];
int entitiesHealth[MAX_ENTITIES];
```

When writing actual assembly code, it’s easy to see why.

To access an attribute of a single entity using the "one single array" variant, we need to perform **one multiplication and two additions**:

```c
// Get the health of entity 5, using the "one single array" variant.
int entityIndex = 5;
int health = *(entities + sizeof(struct entity) * entityIndex + 3);
```

Whereas with the "several arrays of attributes" variant, accessing an attribute is only **one single addition**:

```c
// Get the health of entity 5, using the "several arrays of attributes" variant.
int entityIndex = 5;
int health = *(entitiesHealth + entityIndex);
```

---

Link’s Awakening has about 35 of these entity attribute arrays. And the purpose and behavior of these attributes is often difficult to figure out.

After spending some time trying to make sense of some of the less-often used attributes, I eventually took another approach.

As the history records, Link’s Awakening was started right after the release "Zelda: A Link to the Past" release, by Nintendo employees working after-hours. Using a spare Game Boy development kit, they were trying to see if an ambitious Zelda game, similar to the SNES version, could run on the much-less-powerful Game Boy.

Given than the programmer team was partially made of the same programmers than "A Link to the Past", **could it be that they re-used some of the code structures**? This was worth checking out.

Turns out that a [fairly complete disassembly of Zelda SNES](https://web.archive.org/web/20180315181518/http://www.zeldix.net/t143-disassembly-zelda-docs) does actually exist. And indeed, some of the entities data structures look similar! This provided some hints to some of the less-used entities tables.

For instance one of these, `wEntitiesPhysicsFlagsTable`, exposes flags about the entity physics and rendering: whether it has a shadow, or if it reacts to projectiles, and so on. Another table figured out by looking at the Zelda SNES disassembly is `wEntitiesFlashCountdownTable`, which is used to make an entity flash for a while after it received a hit.

## Generic trampoline

A while ago, user `@spaceotter` on Discord asked if a generic trampoline function was available in the game.

### A what?

Remember how the game code has to be divided into [different code sections](/posts/links-awakening-disassembly-progress-report-part-7/#banking), which mostly can't be loaded at the same time? This creates an issue: in this configuration, how is it possible to call, from bank X, a function residing in bank Y? Bank X can't directly `call` of jump to the function, because if bank X is loaded, then bank Y isn't, and _vice-versa_.

**The solution: a trampoline**. It's a small piece of code in bank 0 (the one that is always loaded) that allows to call a function from one bank to another.

The structure of a trampoline is almost always the same:

1. Jump from bank X to bank 0 (which is always loaded);
2. Switch to bank Y;
3. Call the function in bank Y;
4. Switch back to bank X;
5. Return to the caller in bank X.

In Link's Awakening, many trampolines are defined for specific uses: the target bank, function and return bank are hardcoded. As a trampoline is only a few instructions, hard-coding and duplication isn't that bad. And if you have the original source code of the game, adding another ad-hoc trampoline when needed is easy.

But the ROM-hacking community usually doesn't have the original source code of the same. And most of the ROM-hacking work is patching existing functions at specific places, to call newly-added code. It is quite useful for new code to call existing functions, but what if a trampoline for these functions doesn't exist in the original game – or exists, but returns to the wrong bank?

This is where a generic trampoline function is really useful. Until a few days, I though developers never bothered to actually code one. But as I was randomly browsing some code in bank 0, I found this piece of code:

```m68k
func_BD7:
    ld   a, [$DE01]
    ld   [MBC3SelectBank], a
    call label_BE7
    ld   a, [$DE04]
    ld   [MBC3SelectBank], a
    ret
```

When called, `$DE01` and `$DE04` are usually two different bank numbers, and the address of a function is also stored… Here we are: this is actually our generic trampoline!

Here is the documented version of it:

```m68k
; Generic trampoline, for calling a function into another bank.
Farcall:
    ; Switch to bank wFarcallBank
    ld   a, [wFarcallBank]
    ld   [MBC3SelectBank], a
    ; Call the target function
    call Farcall_trampoline
    ; Switch back to bank wFarcallReturnBank
    ld   a, [wFarcallReturnBank]
    ld   [MBC3SelectBank], a
    ret
```

This function is **only used in three different places**: once in the credits, and twice in palette-related code. It was probably added to the code base while making the DX version – but wasn't ever used a lot. Maybe because it doesn't preserve some of the registers (making argument passing cumbersome), or because it is slower than a hardcoded trampoline for a specific use.

But ROM-hackers should enjoy this: hardcoded-trampolines cannot be easily patched into the original binary, so a generic function may prove useful to hook new code into the game.

## What's next?

Now that the disassembly is complete, and the entity system is getting in a decent shape, the next important milestone is to **make the disassembly shiftable**. Work has [already begun](https://github.com/zladx/LADX-Disassembly/issues/151) – and we'll see how and what does that mean for the project in the next progress report.
