---
layout: post
title: Special effects in Link’s Awakening
lang: en
date: 2016-08-14 10:22
---

[Zelda: Link's Awakening (1993)](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Link%27s_Awakening) is fondly remembered by many players. Whether you played the original black-and-white version or the color remake, you probably remember an oniric story, the whimsical characters, an immersive soundtrack… This is also the game where appeared many iconic elements of the Zelda series: playable tunes on music instruments, compass and boss keys in dungeons, and so on.

When I played this game again recently, I was surprised by the amount of custom gameplay behaviors, one-shot sequences, and graphical effects. The game engine is simple and robust – but on top of it there is a ton of custom coding.

For instance, Link can walk around the map with pixel-per-pixel moves (unlike Pokemon, which moves block-by-block).

![Link's Awakening Sub-block physic engine](/images/zelda-links-awakening-sfx/LADX-move.gif "Link moves pixel-per-pixel, unlike some other games released years after.")

At some point, you get the Roc Feather, an item that opens a new mechanic: jumping over holes.

![Link's Awakening Jumping with the Feather](/images/zelda-links-awakening-sfx/LADX-feather.gif "This is basic physics, but it becomes more interesting later.")

Or catching items mid-air.

![Link's Awakening Catching item mid-air](/images/zelda-links-awakening-sfx/LADX-flying-item.gif "Now is is some unusual mechanics.")

And also, when waking over a hole, it will attract you, but give you a chance to stand back over firm ground.

![Link's Awakening Attracting hole](/images/zelda-links-awakening-sfx/LADX-hole.gif "Holes in the ground are forgiving.")

Later in the game, you can also fly over multiple holes.
The physic engine also allows the player to swim, dive…

![Link's Awakening Swim and dive](/images/zelda-links-awakening-sfx/LADX-swim.gif "This sequence where Link meets the fisherman under the bridge was a nice touch.")

… or to switch from the standard top-down view to a sideway view — including during an epic boss-fight.

![Link's Awakening side-scrolling](/images/zelda-links-awakening-sfx/LADX-side-scrolling.gif "Side-scrolling is actually just a flag that slighly changes the physics.")

Some transitions attempt to simulate a 3D-effect (or at least some depth).

![Link's Awakening Opening the Eagle Tower](/images/zelda-links-awakening-sfx/LADX-tower.gif "This is a rather basic effect – but still, it conveys the intention pretty well.")

Characters will sometimes follow you. For instance, a ghost.

![Ghost following you](/images/zelda-links-awakening-sfx/LADX-ghost.gif "The Game Boy doesn’t have an alpha channel for translucency – so instead the ghost is rendered every other frame.")

Or a dog, attached to you by a semi-translucent chain which moves realistically.

![Link's Awakening Bow-wow with realistic chain](/images/zelda-links-awakening-sfx/LADX-bow-wow.gif "Look at how each chain-link has its own physics. It features the same translucency trick, too.")

When powering-up the console, many Game Boy titles would jump you right to a title screen. Link's Awakening does better, and open with a nice cinematic, packed with sprites and differential scrolling.

![Link's Awakening Introduction Sequence](/images/zelda-links-awakening-sfx/LADX-sea.gif "Shouldn't have played the Song of Storms.")

The game engine also has smooth screen transitions, like a fade-to-white between the interior or the exterior of a map…

![Link's Awakening fade-to-white transition](/images/zelda-links-awakening-sfx/LADX-house-fade.gif "A light touch, but noticeable nonetheless.")

… or even an eerie transition in the Dream House.

![Link's Awakening Dream House transition](/images/zelda-links-awakening-sfx/LADX-dream.gif "The transition looked smoother on real hardware.")

All these small touches to the physics engine and graphic visual effects seemed natural while playing the game – but it was actually quite amazing for a Game Boy game. Although not all of these effects present technical difficulties, the amount and the coordination of all this custom programming makes for a really immersive experience.

## Disassembling Link's Awakening

I was recently looking for a disassembly of Link's Awakening source code, to see how some of the effects where implemented. And although [Zelda: A Link to the Past](http://winosx.com/hosted_files/Zelda_Link_to_the_Past_Dissasembly.txt) on the Super NES has been mostly reverse-engineered, and [Pokemon Red and Blue](https://github.com/pret/pokered) have been completely disassembled, there is no extensive disassembly of Link's Awakening source code.

However an open-source project started [poking into the game's disassembly](https://github.com/mojobojo/LADX-Disassembly) – and although it is still in early stage, it was a really good start.

So I started to look more into the source code, connecting a debugger to the game, setting breakpoints, and try to see how these things worked. Reverse-engineering assembly code is quite slow, but I'll try to post some findings on this blog.
