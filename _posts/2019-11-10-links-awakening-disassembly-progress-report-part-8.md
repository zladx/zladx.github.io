---
layout: post
title: "Link’s Awakening disassembly progress report – part 8"
lang: en
date: 2019-11-11 08:56
---

In the past weeks, a lot of work related to entities got made. The entities placement data was parsed, and the entities handlers were finally all figured out. Let’s dive in!

## Entities placement data

First, what’s an entity? The “entity” term is vague, and may have several meanings. In this context, an entity represents a dynamic element in a room – such as an NPC, an enemy, an interactive device, and so on (as opposed to static room building blocks: walls, floor, pits, etc.).

<span class="pixel-art gameboy-screen">
![A screenshot of Marin singing](/images/zelda-links-awakening-progress-report-8/only-background.png)
</span><br>
_Here’s how a room look like with only the static objects (but without entities)._

<span class="pixel-art gameboy-screen">
![A screenshot of Marin singing](/images/zelda-links-awakening-progress-report-8/only-entities.png)
</span><br>
_And here’s how the room entities look like._



(Sidenote: you may ask, “So entities are simply sprites, right?” Well, not exactly. A sprite is a simple 8x16 pixels image displayed over the background. An entity will usually display itself by managing several independent sprites.

For instance, Bow-Wow is a single entity composed of several sprites: two for the head, one for the shadow, and four for the chain.)

Now, how are entities in a room defined? Very simply, **each room has an associated list of entities**, indexed by the room id. When loading a new room, the game only has to:

1. Use the room index to find the address of the list for that room;
2. Walk the entities list, and for each value create an entity at the given position.

But until now, these lists weren’t parsed: although strictly speaking the entities placement data had been dumped, only raw unstructured bytes were present.

```m68k
; data/entities/entities.asm

; Entities placement data.
; Each entry places entities at a specific location in a room.
;
; TODO: write a proper Python script to generate the pointers tables
; and entities objects properly.

    db   $FF, $FF, $24, $39, $FF, $05, $42, $32, $2C, $55, $2C, $FF, $14, $17, $03, $42
    db   $FF, $13, $17, $66, $16, $15, $1C, $33, $1C, $FF, $23, $59, $FF, $31, $27, $45
    db   $19, $FF, $FF, $27, $20, $FF, $22, $90, $27, $90, $34, $90, $05, $42, $FF, $11
    db   $27, $18, $27, $61, $27, $68, $27, $FF, $FF, $24, $29, $FF, $35, $29, $14, $17
    db   $67, $16, $FF, $44, $1E, $26, $19, $35, $19, $FF, $67, $17, $55, $16, $23, $1E
    db   $FF, $34, $61, $38, $81, $36, $82, $FF, $34, $19, $35, $19, $44, $19, $45, $19
    db   $FF, $14, $20, $52, $1C, $57, $1C, $FF, $43, $1E, $46, $1E, $54, $19, $55, $19
    ; continued for 300 lines…
```
_The raw bytes for entities lists are not very readable. Although if you squint, you can notice the list separator._

Writing a [Python script](https://github.com/zladx/LADX-Disassembly/blob/7f2c25ba394b75748e7ceb55677bc9d6b5115c70/tools/generate_entities_data.py) to parse the entities was easier than parsing the room static objects: the [entities lists data format](https://github.com/zladx/LADX-Disassembly/wiki/Maps-data-format#entities) is quite straightforward to parse, and some of the static objects code structure was reused.

Also, the static objects data format had a lot of quirks (unused labels, duplicated rooms, invalid pointers…). But for entities lists, the only intricacy was some lists being referenced by multiple rooms – which wasn't hard to detect and handle properly.

In the end, it only took a couple of hours to generate a [parsed version of the entities lists](https://github.com/zladx/LADX-Disassembly/tree/7f2c25ba394b75748e7ceb55677bc9d6b5115c70/src/data/entities):

```m68k
; data/entities/indoors_a.asm
; File generated automatically by `tools/generate_entities_data.py`

IndoorsA00Entities::
  entities_end

IndoorsA01Entities::
  entities_end

IndoorsA02Entities::
  entity $2, $4, ENTITY_INSTRUMENT_OF_THE_SIRENS
  entities_end

IndoorsA03Entities::
  entity $0, $5, ENTITY_OWL_STATUE
  entity $3, $2, ENTITY_SPIKED_BEETLE
  entity $5, $5, ENTITY_SPIKED_BEETLE
  entities_end

IndoorsA04Entities::
  entity $1, $4, ENTITY_SPARK_CLOCKWISE
  entity $0, $3, ENTITY_OWL_STATUE
  entities_end

IndoorsA05Entities::
  entity $1, $3, ENTITY_SPARK_CLOCKWISE
  entity $6, $6, ENTITY_SPARK_COUNTER_CLOCKWISE
  entity $1, $5, ENTITY_MINI_GEL
  entity $3, $3, ENTITY_MINI_GEL
  entities_end

; continued…
```

Easy enough: each list is associated to a room, and an entity is defined by its vertical position, horizontal position, and type. A nice, well-structured data format, without surprising behaviors. Thanks, original game developers.

Of course this nice readable list owes much to a couple of macros, that help to transform the readable values into a sequence of bytes:

```m68k
; code/macros.asm

; Define an entity in an entities list
; Usage: entity <vertical-position>, <horizontal-position>, <type>
entity: macro
    db   \1 * $10 + \2, \3
endm

; Mark the end of an entities list
entities_end: macro
    db   $FF
endm
```

## Entities handlers

Once entities are loaded in a room, they need to actually do something. For this, each entity has an associated entity handler. This piece of code is responsible for defining **how the entity looks, how it is animated, and how the player can interact with it**.

Entities handler are executed on every frame, for each entity. This is implemented by having a **large table of function pointers** to all entities handlers.

On each frame, the game will enumerate all entities, and:

1. Load the current index of the entity,
2. Lookup the address of the handler for this entity in the handlers table,
3. Execute the entity handler.

Until know, although the code banks containing the entity handlers lookup table and code has been identified, the code fragments weren’t properly sorted out. All of this looked like a mess of instructions, dozens of thousands of them.

```m68k
; Table of entities handlers
; First 2 bytes: memory address; third byte: bank id
EntityPointersTable::
._00 db $34, $6A, $03
._01 db $61, $44, $19
._02 db $96, $66, $03
._03 db $E3, $7B, $18
._04 db $B2, $69, $03
._05 db $28, $53, $03
._06 db $49, $52, $03
._07 db $DD, $7B, $07
._08 db $66, $79, $18
._09 db $E9, $57, $03
._0A db $26, $6A, $03
._0B db $27, $58, $03
; continued…
```

Cross-referencing all these function pointers to their respective location in the source code was tedious, and took several weeks.

But now, every handler has been labeled and cross-referenced in the handlers table. And again, a small `entity_pointer` macro even makes it easy to read:

```m68k
; First 2 bytes: memory address; third byte: bank id
entity_pointer: macro
    db LOW(\1), HIGH(\1), BANK(\1)
endm

; Table of entities handlers
EntityPointersTable::
._00 entity_pointer ArrowEntityHandler
._01 entity_pointer BoomerangEntityHandler
._02 entity_pointer BombEntityHandler
._03 entity_pointer HookshotChainEntityHandler
._04 entity_pointer HookshotHitEntityHandler
._05 entity_pointer LiftableRockEntityHandler
._06 entity_pointer PushedBlockEntityHandler
._07 entity_pointer ChestWithItemEntityHandler
._08 entity_pointer MagicPowderSprinkleEntityHandler
._09 entity_pointer OctorockEntityHandler
._0A entity_pointer OctorockRockEntityHandler
._0B entity_pointer MoblinEntityHandler
; continued…
```

How useful is that?

Well, now it's easy to know which **section of code is responsible for the behavior of a specific entity**. Are you interested by [the exact behavior of arrows](https://github.com/zladx/LADX-Disassembly/blob/7f2c25ba394b75748e7ceb55677bc9d6b5115c70/src/code/entities/arrow.asm)? Do you want to explore all the easter-egg messages [Marin](https://github.com/zladx/LADX-Disassembly/blob/7f2c25ba394b75748e7ceb55677bc9d6b5115c70/src/code/entities/bank5.asm#L2611) can tell to Link when following him? How are the several forms of the [end-game boss](https://github.com/zladx/LADX-Disassembly/blob/7f2c25ba394b75748e7ceb55677bc9d6b5115c70/src/code/entities/bank15.asm#L2904) implemented? You can just follow the handlers table, and start reading the code for these entities.

## What’s next?

Of course, there is still a lot of work to be done regarding entities.

First, it would be nice to **move all entities handler to their own files**. Instead of having large files like `entities/bank15.asm`, they would be split into `entities/arrow.asm`, `entities/marin.asm`, and so on.

Also, the code for these entities is not documented yet: **many helpers used to work with entities are not understood yet**, which makes the code difficult to read. Documenting all these helpers would definitely help.

The way the game loads entities is not completely figured out yet. Notably, the behavior where entities cleared in a room **do not immediately respawn** when moving to another room is still mysterious to me: the game must have a way to keep track of which entities have been destroyed recently (in order not to respawn them), but how?

Last, we can see in the handlers table that several entities have been blanked out during the development of the game – but also that [several entities have associated code, but never appear in the game](https://github.com/zladx/LADX-Disassembly/issues/142). Analyzing the code to see what these entities were supposed to do could sure be interesting.
