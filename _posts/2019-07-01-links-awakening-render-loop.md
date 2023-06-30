---
layout: post
title: An in-depth look at Link’s Awakening render loop
author: kemenaran
lang: en
date: 2019-06-30 23:15
---

We’ve seen previously [how Link’s Awakening renders the opening cutscene](/posts/links-awakening-rendering-the-opening-cutscene/). This time, let’s take a step back, generalize, and have a look at the main render loop.

## The game’s core

Games are usually based on a main loop. Conceptually, it looks like this:

``` c
while (true) { // loop forever
  processInput();
  updateGameState();
  renderFrame();
  waitForNextFrame();
}
```

In plain text, the main loop repeats the same operations, once per frame, over and over:

- Read the joypad values (i.e. which buttons are pressed),
- Update the game state according to the new time and input (for instance move the character to the right).
- Write the required graphics into the video memory,
- Wait for the graphic hardware to process the current frame,
- Once the frame has been displayed, loop and start computing the next frame.

Of course this is a simplification, and a few key elements have been omitted (for instance there is no audio there). For more information, you can read this much more extensive article about [the render loops generic structure](http://gameprogrammingpatterns.com/game-loop.html).

Link’s Awakening makes no exception, and has its own render loop, right after the initialization code. Let’s see how it is handled.

<!--more-->

## At the start

The first thing the loop does is to set a flag that signals that the graphic hardware just rendered a new frame — and that we are about to start a new loop. This will turn useful later.

``` nasm
RenderLoop::
    ; Set DidRenderFrame
    ld   a, 1
    ld   [hDidRenderFrame], a
```

## Scrolling the background

We have seen that the Game Boy can display a scrollable tiled Background – which is often the basis for the rendering.

The Game Boy graphic hardware will read the scroll position of the background from specific memory addresses: `$FF43` for the X value, and `$FF42` for the Y value. These locations are often referenced as `rSCX` and `rSCY` (for _ScrollX_ and _ScrollY_). Writing into these values will change the position of the background window. Simple enough.

However, when the game wants to change the background scroll position, it often needs to compose several values together. In order to do this, the game defines several indirections:

- `hBaseScrollX` and `hBaseScrollY`, which store the background reference scroll position,
- `WR0_ScrollXOffsetForSection` and `WR0_ScrollYOffsetForSection`, to scroll the background during HBlank for differential scrolling effects,
- `WR0_ScreenShakeHorizontal` and `WR0_ScreenShakeVertical`, to store an offset which will be added to the reference position for screen-shaking effects.

The game can then compose these values during the main render loop (or the during the HBlank period) to apply various effects.

_There is also a special mode, controlled by a flag at the `$C500` address, which alternate the scroll position between 0 and 128 every other frame (I couldn’t yet understand when this effect is used though)._

Here is the relevant code. First, the section for handling the vertical scroll position.

``` nasm
    ; Set ScrollY

    ; Special case for $C500 == 1 (alternate background position)
    ; If $C500 != 0...
    ld   a, [$C500]
    and  a
    jr   z, .applyRegularScrollYOffset
    ; and GameplayType == OVERWORLD...
    ld   a, [WR1_GameplayType]
    cp   GAMEPLAY_OVERWORLD
    jr   nz, .applyRegularScrollYOffset
    ; set scroll Y to $00 or $80 alternatively every other frame.
    ld   a, [hFrameCounter]
    rrca
    and  $80
    jr   .setScrollY

.applyRegularScrollYOffset
    ; Regular case: add the base offset and the screen shake offset
    ld   hl, WR0_ScreenShakeVertical
    ld   a, [hBaseScrollY]
    add  a, [hl]

.setScrollY
    ; Write the computed value into the reference hardware address
    ld   [rSCY], a
```

And just next comes the code for the horizontal scroll position. This one doesn’t supports as many effects, and is simpler to read.


``` nasm
    ; Set ScrollX

    ; Add the base offset and the screen shake offset
    ld   a, [hBaseScrollX]
    ld   hl, WR0_ScreenShakeHorizontal
    add  a, [hl]
    ; Also add another offset (purpose unknown for now)
    ld   hl, $C1BF
    add  a, [hl]
    ; Write the computed value into the reference hardware address
    ld   [rSCX], a
```

## Loading new data

Now the render loops splits into two main paths. The code will either:

- load new data,
- or render an interactive frame.

The first path is for loading new data. This mode is only used while the LCD screen is turned off. In this mode the code won’t actually render anything: it will just load the required resources, and wait for the next frame to render a new frame properly.

``` nasm
    ; Parting of the ways

    ; If there are Tiles or Background Maps data to load,
    ; load new data and return.
    ld   a, [wTileMapToLoad]
    and  a
    jr   nz, RenderLoopLoadNewMap
    ld   a, [wBGMapToLoad]
    cp   $00
    jr   z, RenderFrame
```

In this data-loading path, the code will:

- Determine what kind of audio sample needs to play while the screen is off,
- Load the new map data, tiles, background or sprites,
- Then wait for the next frame.

``` nasm
; Data loading path

RenderLoopLoadNewMap::
    ; Control audio during the transition
    ld   a, [WR1_GameplayType]
    cp   GAMEPLAY_MARIN_BEACH
    jr   z, .playAudioStep
    cp   GAMEPLAY_FILE_SAVE
    jr   c, .playAudioStep
    cp   GAMEPLAY_OVERWORLD
    jr   nz, .skipAudio
    ; GameplayType == OVERWORLD
    ld   a, [WR1_GameplaySubtype]
    cp   GAMEPLAY_WORLD_DEFAULT
    jr   nc, .skipAudio

.playAudioStep
    call PlayAudioStep
    call PlayAudioStep
.skipAudio

    ; Load new map tiles and background
    di   ; disable interrupts
    call LoadMapData
    ei   ; re-enable interrupts

    ; Play more audio
    call PlayAudioStep
    call PlayAudioStep

    ; Jump to the end of the render loop
    jp   WaitForNextFrame
```

And that’s all for the data-loading path.

## Rendering a standard frame

If no additional data need to be loaded, we can render an actual frame.

First thing the game will do is to ensure the LCD screen flags are in a consistent state.

The `rLCDC` (for `LCD Control`) memory location is composed of several flags that control the behavior of the LCD screen:

- Bit 0 - Is the Background displayed?
- Bit 1 - Are Sprites displayed?
- Bit 2 - What size are the sprites? (8x8 or 16x16)
- Bit 3 - Which memory area is used to display the Background?
- Bit 4 - Which tilemap is used to display the Background?
- Bit 5 - Is the Window displayed?
- Bit 6 - Which tilemap is used to display the Window?
- Bit 7 - Is the LCD screen on or off?

When the game needs to manipulate the LCD Control flags, it actually writes into the intermediary variable `WR1_LCDControl`. This variable is then reported in the actual `rLCDC` memory during VBlank.

Note that the code will always set the 7th bit of `rLCDC` to `1`, whatever the `WR1_LCDControl` specifies. This is probably a safeguard: the game never needs to actually shut down the screen, and is it a touchy operation that can [damage the hardware](http://bgb.bircd.org/pandocs.htm#lcdcontrolregister) under some circonstances – so it was disabled outright.

```m68k
RenderFrame::
    ; Update LCD status flags

    ; Load the LCD Control flags requested by the game
    ld   a, [WR1_LCDControl]
    ; Discard the 7th bit ("Is LCD screen on or off?")
    and  $7F
    ; Load the actual LCD Control flags
    ld   e, a
    ld   a, [rLCDC]
    ; Set the 7th bit to 1 ("LCD screen is on")
    and  $80
    ; Apply the values extracted from WR1_LCDControl
    or   e
    ; Set the LCD Control flags
    ld   [rLCDC], a
```

### Incrementing the frame counter

The next step is to increment the global frame counter.

As it is stored on a single byte, it will increment up to `FF` – and then wrap around and start at `00` again.

The global frame counter is used for controlling a lot of effects. For instance:

- when should a cutscene transition to the next sequence?
- at which rate should the tiles be animated?
- when should the characters move?

All these effects look into the frame counter, to see if this is the right time to render an animation.

``` nasm
    ; Increment the global frame counter
    ld   hl, hFrameCounter
    inc  [hl]
```

### Another VBlank hack

The next snippet is a hack for a very specific moment. It is triggered at the end of the Intro sequence, when displaying the "The Legend of Zelda" title logo.

As you may remember from the game, the logo appears with a special scaling effect. The Game Boy is not capable of such scaling effects natively – so like many others, this effect is performed by manipulating the background scroll position while the frame is being rendered.

I won’t enter into details for now — but at least this is why it this snippet needs to be inserted at a very specific place of the render loop (rather than in the dedicated gameplay handler).

``` nasm
    ; Special case for the intro title screen

    ; If GameplayType == INTRO...
    ld   a, [WR1_GameplayType]
    cp   GAMEPLAY_INTRO
    jr   nz, RenderWarpTransition
    ; and the GameplaySubtype is equal or above the title screen...
    ld   a, [WR1_GameplaySubtype]
    cp   $08
    jr   c, RenderWarpTransition
    ; Apply the background scroll manipulations for the logo
    ld   a, $20
    ld   [SelectRomBank_2100], a
    call RenderTitleLogo
```

## Warp effects

The game will often warp Link into a new position, with several visual effects:

- When Link gets a new Siren Instrument, he is warped outside of the dungeon with a **fade-out effect** : first the background fades, then the sprites.
- Link can use one of the four Teleporters on Koholint island, which will warp him like if he was **propelled out of a cannon**.
- The Dream Shrine will warp link into a strange place where the Pegasus Boots can be found, with a **wavy effect** that affects the whole screen.
- Playing Manbo’s Mambo song on the Ocarina will transport link to Manbo’s pond, using the same kind of wavy effect.

This section of the render loop controls the wavy effect of the Dream Shrine and Manbo’s song transition. If such a transition is occurring, the game will render the wave effect – and then jump to the end of the render loop, without further rendering.

_As this section of code calls into several unknown functions, I abbreviated it for now._

``` nasm
RenderWarpTransition::
    ; If WarpTransition != 0, render the wavy warp effect
    ld   a, [WR0_WarpTransition]
    and  a
    jp   z, RenderInteractiveFrame

    ; Render the wavy warp effect
    ; (snip)

    ; Jump to the end of the render loop without further rendering
    jp   WaitForNextFrame
```

## Rendering an interactive frame

If we are not rendering a special effect (like the warp) transition, it is now time to render an interactive frame. This means reading the joypad values, and react to the button presses, the passing time, and so on.

First the game will copy some of its low-level working values into the graphics hardware.

``` nasm
RenderInteractiveFrame::
    ; Update graphics registers from game values
    ld   a, [WR1_WindowY]
    ld   [rWY], a
    ld   a, [WR1_BGPalette]
    ld   [rBGP], a
    ld   a, [WR1_OBJ0Palette]
    ld   [rOBP0], a
    ld   a, [WR1_OBJ1Palette]
    ld   [rOBP1], a
```

Then the current audio track sample gets played.

``` nasm
    call PlayAudioStep
```

At last we can read the joypad values. This function will read the pressed buttons, and store them into the `hPressedButtonsMask` variable. This will allow the game to react to joypad changes.

``` nasm
    call ReadJoypadState
```

## Circulez

For some reason, the loading of new tiles is actually done by the VBlank interrupt handler.

This means that if any new tiles need to be swapped in, we must wait for the next VBlank – and thus jump directly to the end of the render loop.

``` nasm
    ; If Background tiles or Ennemies tiles or NPC tiles need to be updated…
    ld   a, [hNeedsUpdatingBGTiles]
    ld   hl, hNeedsUpdatingEnnemiesTiles
    or   [hl]
    ld   hl, WR0_needsUpdatingNPCTiles
    or   [hl]
    ; Jump to the end of the render loop:
    ; the code executed on VBlank interrupt will load the required data.
    jr   nz, WaitForNextFrame
```

## Debug tools

Link’s Awakening developers wrote built-in debug tools during the development of the game. And like many games, to protect against unexpected changes, they didn’t remove the debug tools when shipping the game — but merely disabled them. This means we have access to a wide range of debug tools, if we can find a way to re-enable them.

Fortunately this work has been done before. [“The Cutting Room Floor” page on Link’s Awakening debug tools](https://tcrf.net/The_Legend_of_Zelda:_Link's_Awakening#Debug_Utilities) tells us all about enabling and using the build-in debug tools.

The game defines three sets of debug utilities, activated by flags at `$0003`, `$0004` and `$0005`. If the ROM is edited (or a cheat is used) to set these addresses to a non-zero value, the corresponding debug tools are activated.

The flag at `$0003` (named `ROM_DebugTool1` in the disassembly) activates the main debug toolset. Some of them are implemented right in the render loop – so the game will first check to see if the debug tools are enabled.

``` nasm
    ; Debug functions

    ; Check if debug mode is enabled (DebugTool1 != 0)
    ld   a, [ROM_DebugTool1]
    and  a
    jr   z, RenderUpdateSprites
```

The first tool implemented in the Render loop is the **Engine freeze**. When pressing the _Select_ button, all the rendering is frozen. Animated tiles are static, NPCs and ennemies don’t move — only the music still plays normally. This is a feature probably intended to examine animated frames more easily, and take precise screenshots.

``` nasm
    ; Isn’t engine already paused?
    ld   a, [WR1_EnginePaused]
    and  a
    jr   nz, .engineIsPaused

    ; If any of the directional keys is pressed, don’t attempt to pause the engine.
    ; (This allows using the Select button without enabling Engine freeze.)
    ld   a, [hPressedButtonsMask]
    and  J_RIGHT | J_LEFT | J_UP | J_DOWN
    jr   z, .skipRenderIfEnginePaused

.engineIsPaused
    ; If the Select button isn’t pressed, jump to the end.
    ld   a, [$FFCC]
    and  J_SELECT
    jr   z, .skipRenderIfEnginePaused

    ; If Select button was just pressed, toggle engine paused status.
    ld   a, [WR1_EnginePaused]
    xor  $01
    ld   [WR1_EnginePaused], a

    ; If the engine was just paused, skip the rest of the render loop.
    ; This will bypass animations, AI, etc.
    jr   nz, WaitForNextFrame
```

When pressing _Select_ again, the engine will resume – but with a twist: Free-Movement Mode is now enabled.

**Free-Movement Mode** allows Link to move over any wall, pit, water surface, or anything blocking. Additionally, Link will also move faster than normal. This of course allow developers to quickly move from one place to the other, without bothering about having the right set of items to pass over a specific fence.

To exit the Free-Movement mode, press _Select_ twice: once to freeze the engine again, and once to unfreeze it: this will toggle the Free-Movement Mode out.

``` nasm
    ; If the engine was just resumed, toggle Free-movement mode.
    ld   a, [WR0_FreeMovementMode]
    xor  $10
    ld   [WR0_FreeMovementMode], a
    jr   WaitForNextFrame
```

Note that only the Free Movement switch is written in the render loop: the actual implementation is in the physics engine.

Last, the code will check if the Engine wasn’t paused previously, and skip further rendering if needed.

```
.skipRenderIfEnginePaused
    ; If the engine is paused, skip the rest of the render loop.
    ; This will bypass animations, AI, etc.
    ld   a, [WR1_EnginePaused]
    and  a
    jr   nz, WaitForNextFrame
```

If we know the engine wasn’t frozen, it is now time to render some motion.

## Preparing sprites

At the beginning of each render loop, before the gameplay code runs, all sprites are initially hidden.

This ensures that only sprites explicitly made visible by the gameplay code will appear on screen. And it makes hiding an NPC or sprite element easy: just don’t explicitly tell it to be visible.

```
RenderUpdateSprites::
    ; If not in Inventory, initially hide all sprites
    ld   a, [WR1_GameplayType]
    cp   GAMEPLAY_INVENTORY
    jr   nz, .resetSpritesVisibility

    ; If Inventory is actually visible, leave sprites visible
    ld   a, [WR1_GameplaySubtype]
    cp   GAMEPLAY_INVENTORY_DELAY1
    jr   c, RenderGameplay

.resetSpritesVisibility
    callsw HideSprites
```

## Execute gameplay code

This is where real things happens.

```
RenderGameplay::
    call ExecuteGameplayHandler
```

Inside this function, the code will do a series of repeated steps: retrieve a variable storing some state in RAM, and dispatch to handlers using a `switch`-like statement. The state will get more and more specific, like:

`ExecuteGameplayHandler:` The game is on the introduction cutscene: jump to `IntroHandler`<br>
`    ▸ IntroHandler:` The cutscene is at the second part: jump to `IntroBeachHandler`<br>
`        ▸ IntroBeachHandler:` Marin is walking slow: animate NPC and background

And so on.

The gameplay code will:

- schedule the loading of new data (tiles, background map, music, and so on);
- update the internal gameplay state;
- update copies of the hardware state (scroll positions, sprites coordinates, etc).

Unfortunately this article is already too long, so details will have to wait for a follow-up article. In the meantime, [have a look at the actual code](https://github.com/mojobojo/LADX-Disassembly/blob/2e6d6be4698b43a5eda857e5b20b833bb86b45a5/src/code/bank0.asm#L1167)!

At the end of the `GameplayHandler`, copies of the hardware state are ready to be applied to actual hardware values during the next V-Blank interval.

### Update palettes

Once the gameplay code is executed, it may have defined a new color palette to be loaded.

In this case, some Game Boy Color-specific code will handle loading the palette data, from the index defined in wPaletteToLoadForTileMap.

```
RenderPalettes::
    ; If isGBC…
    ld   a, [hIsGBC]
    and  a
    jr   z, .clearPaletteToLoad
    ; Load palette set defined in wPaletteToLoadForTileMap
    ld   a, $21
    call SwitchBank
    call label_406E

.clearPaletteToLoad
    xor  a
    ld   [wPaletteToLoadForTileMap], a
```

### Render the window submenu

The Game Boy hardware has a notion of “Window”. This is a specific tiled image, that can scroll to overlap partially (or totally) the usual background tiles.

Of course the intended use for the Window is to display HUD elements and status bars in games. And this is exactly what Link’s Awakening uses it for.

During normal gameplay, the Window displays the items and hearts at the bottom of the screen. But when the inventory is visible, the Window overlaps the entire screen.

This stage of the render loop sets the next  Window position target, depending on whether the inventory is currently visible or not.

```
RenderWindow::
    callsw UpdateWindowPosition
```

At this stage, all steps required for an interactive frame are done.

## Waiting for render

The end is near. We’re getting back to the common code path for interactive and non-interactive frame. These are the last steps for preparing the next rendering.

First, the Window position is applied: target position is copied to the hardware registers controlling the window position.

``` nasm
WaitForNextFrame::
    ; Apply target window position
    ld   a, $1F
    call SwitchBank
    call label_7F80
```

Then the first graphic banks (containing tiled graphics) is enabled.

```m68k
    ; Switch to first graphics bank ($0C on DMG, $2C on GBC)
    ld   a, $0C
    call AdjustBankNumberForGBC
    call SwitchBank
```

And last: the flag indicating that a frame was rendered is reset to 0.

``` nasm
    ; Reset didRenderFrame flag
    xor  a
    ld   [hDidRenderFrame], a
```

### Halt

Now our frame is fully ready. We just need to **wait for the Game Boy PPU to render it** to the screen.

This can take a while–and the game can’t do much about it: while the PPU is rendering the frame, most of the data should not be touched in any way.

So we need to wait for the rendering to be done.

Fortunately, there is a way to wait for this without polling the PPU for some state. We can simply **stop the CPU entirely until the frame is rendered**.

This is done with the `halt` instruction. It stops the CPU until the next hardware interrupt. And hopefully, the next interrupt that will be fired will be the `VBLANK` interrupt, signaling that the rendering is done.

``` nasm
    ; Stop the CPU until the next interrupt
    halt
```

Hopefully, when the CPU resumes execution of our code, our frame will be fully processed.

However, there are no guarantees. Maybe another interrupt was fired, and we still need to wait. In that case, **the game code resorts to polling**. The code waits until a flag sets by the `VBLANK` interrupt is set: this will guarantee that the frame has indeed been rendered.

``` nasm
.pollNeedsRenderingFrame
    ; Loop until hNeedsRenderingFrame != 0
    ld   a, [hNeedsRenderingFrame]
    and  a
    jr   z, .pollNeedsRenderingFrame
```

Once the frame was rendered, we can clear the flag immediately…

``` nasm
    ; Clear hNeedsRenderingFrame
    xor  a
    ld   [hNeedsRenderingFrame], a
```

… and start a new interation of the render loop.

``` nasm
    ; Jump to the top of the render loop
    jp   RenderLoop
```

Phew! We’re done.

## Conclusion

Link’s Awakening render loop is a very fine piece of code. Although it runs on the modest Game Boy hardware (underpowered even for its time), cleanliness is not sacrificed to efficiency. It uses the proper indirections when required, like compositing final values from different sources, and does not try to circumvent its render loop (I’m looking at you, Pokémon Red/Blue.)

Link’s Awakening was started as an unofficial side project, to see if an ambitious Zelda game could run on the Game Boy. Which means that **Link’s Awakening programmers had all the experience accumulated while making A Link to the Past**. This probably helped them to anticipate what was needed in a Zelda game, and explains why the code is nicely structured in all regards.
