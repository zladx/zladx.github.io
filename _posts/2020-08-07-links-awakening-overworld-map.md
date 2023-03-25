---
layout: post
title: "The hidden structure of Link's Awakening Overworld map"
lang: en
date: 2020-08-07 08:47
---

The Game Boy, as most gaming platforms at the time, uses tiles for graphics rendering. Instead of drawing individual pixels on the screens, games must first provide _tiles_ (small graphics fragments, usually 8x8 pixels wide), and then combine together this limited number of tiles to draw pictures on the screen.

This technical limitation influences not only the games appearance, but also the gameplay. This articles goes in-depth into a specific example: how the design of Zelda: Link's Awakening overworld map is influenced by the underlying tile-based rendering.

## Challenges of tiles-based rendering

To display an image on screen, as all tile-based games, the game engine must first copy the required tiles to the Game Boy <abbr title="Video memory">VRAM</abbr>.

This brings two challenges:
- The number of tiles that can fit into VRAM at a given time is extremely limited,
- Changing the tiles stored in VRAM is slow, and can only be done at specific times.

<span style="display: block; text-align: center">
[![The tileset of Link's Awakening Overworld](/images/zelda-links-awakening-overworld-map/overworld_2.dmg.png)](/images/zelda-links-awakening-overworld-map/overworld_2.dmg.png)
<br>
_A part of the tileset used on the Overworld.<br>
This is way to big to fit all in memory at once, so only parts of it can be loaded at a time._
</span>

So in order to display graphics efficiently, great care must be given to the **ressource-management of tiles**.

A modern game engine would probably include a ressource-management system, which would ensure that, for each frame, the tiles required to display the objects on the screen are properly loaded. But the code for such a system would be quite complex: as uploading tiles takes a lot of time, it would have to predict which objects are going to appear on screen. The system would also have to ensure that not too many different objects are going to be visible on screen at once–otherwise there's no space left in VRAM to upload the required tiles.

But on older hardware, such as the Game Boy, VRAM is so limited that every single tile must be put to use. There's no margin left for predictive loading or fancy resource-management systems.

Instead, older games generally use **tilesets**. Tilesets are some fixed sets of tiles that are grouped together, and known to be predictable available at a given time. The game designers typically give each scene its own tileset, and then use a tile editor to draw the rendered frame. And the tilesets can be switched when the game transitions from one scene to another.

As of Link's Awakening, the code responsible for this ressource management has recently been documented. And this is exactly how the game manages tiles. The world map is divided into sections of 2x2 rooms. Each section has an associated tileset, which allows the map feature some variety between the different sections (because they can use different tilesets).

```m68k
OverworldTilesetsTable::
    db   $1C, $1C, $3E, $3C, $3E, $3E, $3E, $30
    db   $0F, $36, $36, $1A, $0F, $34, $0F, $3E
    db   $20, $20, $0F, $38, $28, $28, $32, $32
    db   $20, $20, $38, $38, $28, $28, $32, $32
    db   $0F, $26, $0F, $24, $0F, $1E, $2A, $0F
    db   $26, $26, $2E, $2E, $0F, $2A, $2A, $2A
    db   $0F, $24, $2E, $2E, $3A, $0F, $26, $2C
    db   $22, $22, $22, $0F, $3A, $3A, $0F, $2C
```

An array is not very telling. Let's use a picture instead! And we're lucky, because a few years ago, [Xkeeper](https://xkeeper.net/) generated a map of the Overworld with the tileset IDs overlaid on each section.

[![Overworld map of Link's Awakening, with the tileset ID overlayed on each map section](/images/zelda-links-awakening-overworld-map/overworld-tilesets-thumbnail.jpg)](/images/zelda-links-awakening-overworld-map/overworld-tilesets.png)
_Each 2x2 section of the Overworld map declares its own tileset ID. (Credits: [Xkeeper](https://xkeeper.net/hacking/linksawakening/))_

Quite simple – in theory.

## Technical constraints

Practically, it's not so easy. As we know, in Link's Awakening, when player moves from one room to another, the game animates the changes smoothly. Which means that during the transition, **both the previous room and the next one are visible**.

So during a room transition, both the old and new tileset need to be available in VRAM. Otherwise, glitches will ensue: if the tileset of the new room overlaps the tiles of the previous room, the previous room will shortly be rendered with incorrect tiles. Every time the game designers want to introduce new tiles, they have to think about the transitions from all the adjacent rooms. Moreover, this is hard to debug: the glitches could manifest only when visiting the rooms in a specific order.

Link's Awakening engine has a solution for this: **put structural constraints on the map design** to avoid the issue almost entirely. Instead of testing every combination of rooms and tilesets, the game instead:

1. Defines a special "Keep current" tileset code,
2. Ensures that the player always goes through a "Keep current" tileset before loading a new one.

The "Keep current" tileset code is a special tileset ID, that instructs the game engine not to load any new tileset data for the current section of 2x2 rooms. You can spot it on the tilsets map above: it has a `0x0F` ID.

How does it solves our tileset issues? Well, a "Keep current" tileset is kind of a buffer zone between two different tilesets. A section with this tileset must be displayable using any of the tilesets of the section leading to it.

For instance, given the following map layout:

```
 ——————————      ——————————————     ———————————
| Section 1 |   |  Section 2   |   | Section 3 |
|           | ↔ |              | ↔ |           |
| Tileset A |   |"Keep current"|   | Tileset B |
 ———————————     ——————————————     ———————————
```

In this layout, depending on the player direction, the Section 2 tileset may be displayed either with Tileset A, or with Tileset B.

Which means that **by design, a "Keep current" section can only use the tiles shared by the adjacent tilesets**, in that case the Tilesets A and B. If this rule is not honored, the graphics of the "Keep current" section will be corrupted.

So by introducing some design constraints, the game avoids to ensure that every tileset has to be compatible with any tileset that could be adjacent to it. Now the game designers just have to ensure that some sections only use a restricted number of tiles shared between the adjacent tilesets. These "Keep current" sections will feature less unique details, but will ensure that transitions between different tilesets are always glitch-free.

## Revealing the hidden structure of the Overworld map

The only thing that remains is to **ensure that the player can never navigate directly from a tileset to another** – but instead always goes through a "Keep current" area first.

Lo and behold, this reveals the hidden structure of Link's Awakening Overworld map.

Here's the same Overworld map than above, with the tilesets overlaid – but this time, the "Keep current" tilesets are highlighted in green.

[![Overworld map of Link's Awakening, with the "No change" tileset overlaid in green](/images/zelda-links-awakening-overworld-map/overworld-tilesets-with-paths-thumbnail.jpg)](/images/zelda-links-awakening-overworld-map/overworld-tilesets-with-paths.png)
_Overworld map of Link's Awakening. In green: the "Keep current tilesets. In red: walls and natural obstacles on the map._

As you can see, the game designers had to put restrictions to ensure that the player can never directly transition from a tileset to another – but instead goes through a "Keep current" tileset first.

How? **By putting walls and obstacles on the map that separate the tilesets**. These are the one highlighted in red on this map; the player can never go through them. The obstacles constraint the player's path, and ensure the tilesets continuity.[^1]

[^1]: Of course there are several exceptions to this:
    * The Photographer Shop section (using tileset `0x1A`), is actually a "Keep current" tileset. But when the Photographer was added in the DX version, the tileset was special-cased to load the shop tiles when entering this room. On other rooms, it behaves like a true "Keep current" tileset.
    * On the Windfish Egg section, tileset `0x3C` can communicate directly with the tileset `0x3E` on the East. For this, the room on the right of the Windfish Egg is special-cased to swap the tilesets smoothly.
    * Around Kanalet Castle, some other sections **do** change tileset without going through a "Keep current" tileset. In that case, we're back to manual tiles management: the connecting rooms are carefully engineered to use the overlapping parts of the two tilesets.

    So the constraint of buffer sections allows to greatly simplify tilesets management – but is still flexible enough to allow exceptions, or even revert to manual tiles management wherever needed.

## Impact on game design

Like all technical restrictions, limitations on tilesets are also a source of creativity.

Because of the "Keep current" buffer tilesets, it's easier not to connect every section of the map to every other: obstacles must be built. But this constraint has upsides: **it gives the map a labyrinthine structure**. And that's helpful for a good game design: it tends to divide the map into distinctly themed sections. Folds also make the world feel larger, like does a curated garden with carefully placed occluders.

The need to interleave buffer tilesets on the map also gives **natural pacing** to the game. Buffer tilesets can't have the same visual complexity than other sections of the map (because they can only use a limited number of tiles). It makes simpler areas alternate with higher-complexity ones. As a result, the player will usually travel through a strongly-themed section, then a more generic one (as they move through a buffer tileset), then again reach another themed section. This sense of rhythm is a key element of a good game design.

---

### Notes
