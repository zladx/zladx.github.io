---
layout: post
title: "Link’s Awakening disassembly progress report – part 10"
lang: en
date: 2020-01-20 08:56
---

## Entities respawn mechanism

In a previous progress report, I wondered how Link’s Awakening respawn mechanism works.

Specifically, when destroying enemy entities on a specific area, moving out and back into this area doesn’t reload all the entities. Only the surviving enemies (if any) are visible. For a moment, at least. After a while, the enemies seems to respawn again.

<span class="pixel-art gameboy-screen">
![A portion of gameplay showing how entities don’t respawn when leaving a room](/images/zelda-links-awakening-progress-report-10/ladx-full-respawn.gif)
</span><br>
_Entities don’t respawn when returning to a previously visited area._

Eventually I found the piece of code responsible for this behavior. Turns out the implementation is cleverly simple.

It relies on two separate mechanisms: a recents rooms list, and flags depending on the entity load order.

### Clearing rooms

The first mechanism used is a 16x16 array, `wEntitiesClearedRooms`. It contains one byte per area (or “room”). When all the enemy entities in a room are destroyed, this is recorded into this array.

When this room is visited later again, the game checks whether the room has been cleared or not before loading the entities. Simple enough.

But **how do entities respawn again after a while?** Well, because the `wEntitiesClearedRooms` also has companion variable: `wRecentRooms`.

`wRecentRooms` stores the six most recently visited rooms. At its core, it’s a simplified implementation of an <abbr title="Least-Frequently-Used cache">LRU cache</abbr>:

- **Each time a room is visited**, it is added to the recents rooms list (except when the room is already in the list);
- **When the list reaches six rooms**, the index resets to the start of the list.

Clean and tight. But importantly, this means that **new rooms will start overwriting older ones**.

How does this relate to entities respawning again? Well, the single and unique purpose of `wRecentRooms` is actually not to store a list of recently visited rooms, but to **detect when a room is evicted from this list**. When a recent room is overwritten by a newer one, the byte corresponding to the evicted room in  `wEntitiesClearedRooms` is reset to zero. Which means the entities of this room will start spawning again when the room is visited.

### Entity flag

The game has actually a finer granularity than that. It's not about whether then entire room is cleared or not: even destroying a single entity in a room will cause it not to respawn the next time (even if other entities in the room still do spawn). How does that work?

<span class="pixel-art gameboy-screen">
![A portion of gameplay showing how only destroyed entities don’t respawn when leaving a room](/images/zelda-links-awakening-progress-report-10/ladx-partial-respawn.gif)
</span><br>
_Only destroyed entities don’t respawn. The others are still loaded when visiting the room again._

Turns out that the `wEntitiesClearedRooms` array doesn't only tell if a room has been cleared or not, but also **which entities have been destroyed in that room**.

For this, entities are identified by their _load order_. Each entity has an index indicating in which order it was loaded into the room. So when an entity is destroyed, the game takes the entity load order, turns it into a bitmask, and stores it into `wEntitiesClearedRooms`.

![A diagram of how the entities load order is encoded](/images/zelda-links-awakening-progress-report-10/ladx-room-entities-diagram.png)

Next time this room will be visited, when each entity is loaded, the game uses the load order to check if the entity has already been destroyed – and skip it if so.


## Statistics

Knowing where we are and how much progress we made is instructing and motivating. For this purpose, similar to [some of the pret projects](https://github.com/pret/pokefirered/blob/master/.travis/calcrom/calcrom.pl), the LADX disassembly now has a script that can output various statistics about the overall completion state of the project.

Here is an example output:

```
$ tools/stats.sh
Number of remaining raw addresses:
   Referencing Home (0000-3FFF):
       0
   Referencing non-Home ROM banks (4000-7FFF):
    2551
   Referencing RAM (8000-FFFF):
    6478

Number of unlabeled functions:
    1033

Number of unlabeled jumps:
    7706
```

This should help to:

- Get a sense of the project completion state;
- Help to identify which banks are shiftable, and which still reference code or data using raw addresses.

In the future, the script may present percentages instead of raw numbers; something like "Unlabeled functions: 1033 (34%)".

## Shiftable bank

Speaking of shiftable banks, work has begun towards making the disassembly shiftable!

**But what's a shiftable disassembly?** When starting a disassembling project, the first step is often to run an automatic disassembler on the whole ROM binary. This automatic disassembler can only decode instructions, and add auto-generated-labels to the most obvious locations. But the output is quite limited: it will have data interpreted as code, no meaningful labels – and, crucially, many memory addresses will be left unresolved.

```m68k
  ; Loading data from an unresolved `$4206` address.
  ld   hl, $4206
  ld   a, [hl]
```

What's the problem with that? Well, if we start tweaking the original code (for instance to add a new feature that wasn't present in the original game), the new code will slightly **push the old code around**. But places in the code using unresolved addresses won't be updated, and will still point to the former location. This will lead to data-corruption and crashes very quickly.

How to avoid these corruptions? Either by:

- **Making sure that new code never shifts the old code around.** This is usually what ROM-hackers do, by inserting carefully crafted jumps to the new code – and it's very cumbersome.
- Or make the reverse-engineered source code **shiftable**, so that new code can be added anywhere without issues.

In shiftable code, all unresolved raw addresses have been resolved to proper labels. Because of that, even if the data location is pushed around by new code, the code referencing this data location will also change – and the game will still work.

```m68k
  ; Loading data from a labeled address.
  ld   hl, Data_004_4206
  ld   a, [hl]
```

Now, resolving data addresses in the whole reconstructed source code isn't easy. There's a reason disassemblers can't do it automatically: the banks system.

When the disassembler sees, for instance, a pointer being created with the address `$4206`, it can't know if this address means:

- "`$4206` in the current bank",
- or "`$4206` in bank 3",
- or even "`$4206` in bank 2 or 3 depending on the color mode".

So cross-referencing these addresses has to be made manually. An human must understand what the code is actually trying to do, and replace the raw address with a label at the right location. And it takes time.

But already, as a first milestone, **the main bank (bank 0) is now shiftable!** That means new code can be added or removed from this bank, without breaking the game. As the bank 0 is always mapped into memory, this is already quite useful to insert some hooks for new features.

And meanwhile, the work to [make the other banks shiftable](https://github.com/zladx/LADX-Disassembly/issues/151) continues. About half of it is now done, but it involves quite a bit of repetitive work (although some of it [has been automated](https://github.com/zladx/LADX-Disassembly/pull/165#issue-362650385)).

Want to give it some help, and **contribute to make Link’s Awakening easier to mod than ever?** Drop on the [Discord channel](https://discord.gg/sSHrwdB)!

