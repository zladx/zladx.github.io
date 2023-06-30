---
layout: post
title: "Link's Awakening: Rendering the opening cutscene"
author: kemenaran
lang: en
date: 2016-09-10 13:07
---

When powering-up the console, after displaying the iconic “Nintendo™” logo, many Game Boy titles jump you right to a title screen.

[Zelda: Link's Awakening](https://en.wikipedia.org/wiki/The_Legend_of_Zelda:_Link%27s_Awakening) does better, and open with a nice opening cutscene, which introduces the plot and the characters of the story. Several smaller animated sequences are also sprinkled through the game – and roughly half-a-dozen were added during the DX remake, as a part of the Photographer sub-quest. The Ending sequence, with its impressive 5-minutes length, also have some nice visual effects exclusive to this segment of the game.

This opening cutscene, as the first sequence of the game, is a good starting point for understanding various special effects used through the game.

<iframe class="img-border" width="320" height="288" src="https://www.youtube-nocookie.com/embed/3eTbjNuHXiM?rel=0&amp;showinfo=0" frameborder="0" allowfullscreen></iframe>

## The sea sequence, stripped

The original Game Boy was first released in 1989, and has quite basic capabilities. The graphic primitives are based on _tiles_, _background_ and _sprites_. Tiles are 8x8 bitmaps, arranged into the grid of a large scrollable background.

This grid is very rigid: that's 8x8 for you, and nothing else. Fortunately, sprites are objects that can move with smaller increments, positioned over the background.

Note that there is no “direct drawing” mode of some sort: you can't draw individual pixels on the Game Boy screen, it has to be part of a 8x8 tile.

This severely limits the drawing possibilities. Any advanced effects will have to use complex workarounds.

To understand, let's have a look at the introduction sea sequence. We're going to strip it of all special effects, and only use background scrolling, tiles and sprites.

_(This can't normally be seen in the game. But now that we have a limited [source code](https://github.com/mojobojo/LADX-Disassembly), we can replace some code to [disable specific features](https://github.com/kemenaran/LADX-Disassembly/commit/83ac7dfeeb970d5aea5dcec75f1ba0b6355dee87), re-assemble the ROM, and run it into our favorite emulator.)_

<span class="pixel-art gameboy-screen">
![Link's Awakening Sea Sequence without special effects](/images/zelda-links-awakening-intro/1-nodiff-nowave-norain.gif)
</span>

Less dramatic, isn't it?

However the reduced motion allows us to see more clearly what is going on. What have we here?

- Several set of _tiles_: for the clouds, upper waves and lower waves,
- The _tiles_ are arranged over a repeating _background_,
- The _background_ window is slowly scrolled from right to left,
- Link's ship is rendered as a _sprite_, with two movements: horizontal (to simulate the ship being attached to the background) and vertical (to render the ship [heave](https://en.wikipedia.org/wiki/Ship_motions#Linear_motion) motion),
- Lightnings are also rendered as _sprites_,
- A dynamic _palette_, briefly changed when a lightning strikes to simulate the indirect light.

Now if we were the developers of Link’s Awakening, what could we add to this scene to spice it up?

## Waves in motion

For now the sea looks very static, almost like a solid surface. Nothing remotely menacing, like a deadly sea ready to sink our ship. Breaking the waves into different overlapping parts would be much better.

Unfortunately the Game Boy doesn't has much control over how the tiles are arranged over the background: a simple 8x8 grid, nothing else.

But luckily we can animate the content of the tiles themselves! And that's what the developers used: they made a small looping animation of overlapping waves, like an animated GIF.

![Link's Awakening Sea Sequence animation loop](/images/zelda-links-awakening-intro/LADX-wave-animation.gif "The grid shows the 8x8 tiles boundaries")

Here is how our scene looks with this wave animation.

<span class="pixel-art gameboy-screen">
![Link's Awakening Sea Sequence with moving waves](/images/zelda-links-awakening-intro/2-nodiff-wave-norain.gif)
</span>

Much better: we can see the waves going one behind each other.

However something looks strange. Due to the way the animation is made, the horizon is now moving up and down. Not very convincing. To avoid this, we'll need a more complex trick.

## Compensating for sea movement

Remember that we are drawing our scene over a scrollable background. The “camera” moving to the right is actually our background window being scrolled on the horizontal axis.

What we could do is also scroll the background up and down over the vertical axis, to compensate the horizon motion. This way the horizon position would appear constant. And this is actually what the game does.

![Link's Awakening Sea Sequence Background movement](/images/zelda-links-awakening-intro/3-nodiff-honzwave-norain-bg.gif)

Nice trick. But one issue remains: although the horizon position looks now fixed, the clouds now appear to be moving up and down.

If only we could move only the _lower part_ of the background, and left the _upper part_ untouched…

Wait, the Game Boy can actually do this – by using the `LCD STAT` interrupt.

## Abusing HBlank

The Game Boy LCD screen renders graphics line by line, sequentially from the top to the bottom. When reaching the end of an horizontal line, the LCD controller makes a small pause (of more-or-less 300 cycles) before drawing the next line: this period between two lines is the _Horizontal Blank_, or `HBlank`. _(The name comes from the old CRT screens, where the electron beam physically needed to move back from the right of the line to the left of the new line.)_

Likewise, when the last line has been rendered, the LCD controller makes a longer pause before jumping again to the top line: this period is the _Vertical Blank_, or `VBlank`.

![Game Boy scanlines](/images/zelda-links-awakening-intro/gameboy-scanlines.png)

Manipulating the Video Memory while the screen is being drawn is quite restricted: during this period many operations on the video memory are not possible, or simply ignored. This is why the logic of most games runs during the `VBlank` period, when nothing is being rendered, and all the video memory can be manipulated freely.

To make it easier, the Game Boy hardware can fire an interrupt when the Vertical Blank period begins (appropriately named the `VBLANK` interrupt).

But the video memory can also be manipulated at the end of each line, during the `HBlank` period — although you have very few cycles to do so. One popular manipulation is to change the x coordinates of the background for each line: this allows to create a wave-effect seen in many games (like [this one](/images/zelda-links-awakening-sfx/LADX-dream.gif)).

Firing an interrupt for every `HBlank` would be quite expensive though – especially considered that usually  most lines will be left unmodified. Fortunately the Game Boy provides a smarter primitive for this: the `LYC` register.

`LYC` stands for _LCD Y Compare_: put the number of a scanline in this register, and the _LCD Status_ interrupt (or `LCD STAT`) will fire whenever `HBlank` occurs on this line specifically. Almost like setting a breakpoint.

And this is what the game does here.

* Put the `$40` value in the `LYC` register (for scanline 64 in decimal),
* Enable the `LCD STAT` interrupt,
* Wait for the next _LCD Status_ interrupt to fire during the `HBlank` period of scanline 64.

When the interrupt occurs, the execution pointer will jump to the address `$0388`, the hardcoded value for this interrupt. The code can then shift the position of the background position after the clouds have been drawn, but before the sea appears.

<span class="pixel-art gameboy-screen">
![Link's Awakening Moving the background offset during HBlank](/images/zelda-links-awakening-intro/LADX-vertical-offset.gif)
</span>

By moving in sync with the waves animation, this gives the illusion that the horizon is stable. Here is what the scene becomes with vertical motion compensated.

<span class="pixel-art gameboy-screen">
![Link's Awakening Sea Sequence Background movement](/images/zelda-links-awakening-intro/4-nodiff-honzwave-norain.gif)
</span>

Note that the horizon motion is not _perfectly_ compensated for: sometimes it moves one pixel up or down. I'm not sure if this is a bug or an intentional feature left there on purpose ; but it arguably looks better than having a perfectly stable horizon.

## Differential scrolling

This is nice, but still lacks motion. To add some depth, an effect often see in 2D games is _differential scrolling_: scrolling portions of the background at different rates, to give an illusion of perspective and depth.

But remember, we still only have a static tiled background here. How can we add a differential scrolling effect on this constrained grid?

Well, we previously shifted the position of the background when the rendering reached a specific scanline:  the same mechanism can be used again, but to shift the background horizontally.

This time we need to break at several different positions, one for each screen section. For this the game will divide the screen into five horizontal sections – and assign a scanline to each section.

Here is the relevant section of the game code that performs this effect.

``` nasm
data_037F:
    ; List of scanlines to divide the screen in horizontal sections.
    ; This is used to enable differential scrolling during the sea intro sequence.
    db $20, $30, $40, $60, $0  ; upper clouds, lower clouds, sea, upper waves, lower waves

; snip...

label_03D9:
    ; Setup the next HBlank interrupt for the Sea intro sequence.
    ; e = Section Index
    ld   hl, $037F     ; hl = $037F + SectionIndex
    add  hl, de        ;
    ld   a, [hl]       ; a = next section scanline
    ld   [rLYC], a     ; Fire LCD Y-compare interrupt when reaching
                       ;   the scanline for the next section.
    ld   a, e          ; a = SectionIndex
    inc  a             ; Increment section index
    cp   $05           ; If SectionIndex != 5
    jr   nz, .return   ;     return
    ; If SectionIndex == 5
    xor  a             ; Reset the section index to 0
```

What all this means? When the scanline for the next section is reached, the `LCD STAT` interrupts fire, and the background is moved. Then the game increments the section index,  retrieves in a list the scanline for the next section, and reprogram the `LYC` register with the new value to break when reaching the next section.

The code for this is actually quite straightforward. I was so happy when I found out the meaning of these numbers stored at `$037F`! It's actually a table, mapping the screen sections indices with a scanline.

Here is how the background is shifted and moved around when rendering a single frame of the Introduction sequence.

<span class="pixel-art gameboy-screen">
![Link's Awakening Sea Sequence Differential scrolling](/images/zelda-links-awakening-intro/LADX-horizontal-offset.gif)
</span>

And here is how the differential scrolling looks in the game.

<span class="pixel-art gameboy-screen">
![Link's Awakening Sea Sequence Background movement](/images/zelda-links-awakening-intro/5-diff-honzwave-norain.gif)
</span>

## Random rain

The last thing missing is the heavy rain pouring over the ship.

These are just three different sprites (long, short, thick) arranged in several horizontal sections, following randomly-chosen predefined patterns.

By the way, the random number generator of the game is quite simple, but does its job well. It's a function of the global frame counter, the previously generated random number, and the current `LY` register value (the number of the scanline being rendered at this time). Random enough.

``` nasm
label_280D:
    ; Return a random number in `a`
    push hl
    ld   a, [hFrameCounter]
    ld   hl, WR0_RandomSeed
    add  a, [hl]
    ld   hl, rLY
    add  a, [hl]
    rrca
    ld   [WR0_RandomSeed], a ; WR0_RandomSeed += FrameCounter + rrca(rLY)
    pop  hl
    ret
```

And finally, with the rain added, here is the Sea intro sequence at it looks like in the game!

<span class="pixel-art gameboy-screen">
![Link's Awakening Sea Sequence Background movement](/images/zelda-links-awakening-intro/6-diff-honzwave-rain.gif)
</span>

All these effects are not unique to Link's Awakening: they are of course found in many other games as well. But this game shows a remarkable combination of technical and artistic skills, associated to create a great atmosphere.

_For more details, you can browse the annotated assembly code for the [LCD Status Interrupt](https://github.com/zladx/LADX-Disassembly/blob/681355e39bf51560d1323717d3a4341a44be85f8/src/main.asm#L665), or the code for the [Introduction sequence gameplay](https://github.com/zladx/LADX-Disassembly/blob/681355e39bf51560d1323717d3a4341a44be85f8/src/bank1.asm#L6786)._
