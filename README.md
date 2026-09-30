# yarlib

Yet another raylib, except for the parts raylib gets wrong. A 2D game
library and a small engine over it, in Ada, where every play session
is a text file and every level is a text file.

GNAT Academic Program capstone project. Proposal title: *Game Engine
PAL*.

## What it is

```ada
with Bedrock.Colors;  use Bedrock.Colors;   --  the GAP foundation crate: types
with Yarlib.Core;     use Yarlib.Core;
with Yarlib.Shapes;   use Yarlib.Shapes;

procedure Hello is
begin
   Init_Window (800, 450, "hello");
   while not Window_Should_Close loop
      Begin_Drawing;
      Clear_Background (Ray_White);
      Draw_Rectangle (100, 100, 200, 80, Red);
      End_Drawing;
   end loop;
   Close_Window;
end Hello;
```

That is raylib's surface, kept on purpose: immediate mode, one loop,
no callbacks, no scene graph, flat modules (Core, Shapes, Textures,
later Text and Audio), batteries included. A beginner draws a
rectangle in six lines.

The renderer is a seam with two bodies: `software` (Yarlib.Raster into
a Bedrock image; complete on its own, no GPU needed, what the tests
and CI use, and what portal will present when its port lands) and
`opengl` (GL 1.1, for a real window today through SDL3). The platform
is the other seam: `null` (no window) and `sdl3`.

**What the seed shows on screen right now:** the window opens and
clears to dark gray, the console works, sessions record and replay,
`arena --frames 60` writes `shot.png` and exits 1. Nothing else is
drawn until milestone 1, the batcher, is written; the console line
`batch dropped N quads` says so. That is the intended state.

Underneath, five things raylib does not do, each cheap and each the
kind of thing that decides whether a student game gets finished:

| | raylib | yarlib |
|---|---|---|
| State | hidden globals; one window, untestable | an explicit `Context`; the flat API is a thin layer over a default one |
| Units | `float` and `int` everywhere, degrees here, radians there | `Scalar`, `Degrees`; the compiler catches the unit bug |
| Failure | logs and returns texture 0; you find out in a week | `Ok` out parameters and preconditions; never a garbage handle |
| Timing | `SetTargetFPS` busy-wait; physics depends on frame rate | `Yarlib.Game_Loop`: fixed step plus interpolation, `Init / Update / Draw` |
| Determinism | none | `Yarlib.Replay`: a session is a `.rec` text file; replay reproduces it exactly; the tests use it, a bug report can attach one |

The vocabulary (`Scalar`, `Vector2`, `Rectangle`, `Color`, `Key`,
`Event`, the pixel `Image`) is not yarlib's: it comes from
[bedrock](https://github.com/GNAT-Academic-Program/bedrock), the GAP
foundation crate, and is the same type in portal and in the editor.
A game withs `Bedrock`, `Bedrock.Colors` and `Bedrock.Input` alongside
the Yarlib packages; there is no conversion at any seam.

And on top, an engine layer for what real engines add that pays for
itself: an ECS (escape, the sibling capstone), scenes as text with hot
reload, systems, and a console that drives all of it with lines.

```
Yarlib.Engine   Scene (text, hot reload), Components, World (escape), Systems, Commands
                                                                        engine/  crate, depends on escape
Yarlib.Core     Context, Shapes, Textures, Game_Loop, Replay, Console   raylib's surface, typed, no globals
Yarlib.Batch    the one funnel every pixel goes through, SPARK          + Platform and Renderer seams, ports
```

A game can stop at any layer.

## What is in the seed

```
src/yarlib.ads              Texture, Bitmap; the vocabulary is bedrock's        Pure
src/yarlib-batch.ads        the funnel: Push_Quad, Well_Formed, Draw_Call         PLACEHOLDER, SPARK: milestone 1
src/yarlib-raster.ads       software rasterizer: triangles, textures, blending    done
src/yarlib-platform.ads     the platform seam (spec only)                         done
src/yarlib-renderer.ads     the renderer seam (spec only)                         done
src/yarlib-png.ads          PNG writer, no zlib; screenshots                      done
src/yarlib-input.ads        Event, Event_Queue, State: input as values            done, SPARK
src/yarlib-core.ads         Context; window, frame, time, input, Camera2D         done
src/yarlib-shapes.ads       Draw_Rectangle, _Pro (rotated), Draw_Line_Ex, Lines   done
src/yarlib-textures.ads     Load from pixels, Checkerboard, Draw_Texture, _Pro    done
src/yarlib-game_loop.ads    fixed timestep driver, generic over Update and Draw   done
src/yarlib-replay.ads       record and replay a session as text                   done
src/yarlib-console.ads      lines in, lines out; a registry of handlers           done
ports/platform/{null,sdl3}  no window / SDL3 window + GL 2.1 context (200-line binding)
ports/renderer/{software,opengl}  Raster into a Bedrock image / GL 1.1 client arrays, no loader
showcase/                   arena: Init/Update/Draw, console commands, --record/--replay/--frames
tests/                      raster, batch, input, core, camera, loop+replay, console  57 checks
engine/src/                 Components, World (escape assembly), Scene, Systems, Commands   done
engine/showcase/            arena2: the arena as arena.scene; edit it live
engine/tests/               scene grammar, console, and the escape-gated behaviour   15 checks
editor/README.md            the contract for the adi2 editor                      contract only
```

Everything runs. Two holes, one per team:

- **`Yarlib.Batch.Push_Quad`** (this project, milestone 1): nothing
  draws until it is written. Thirty lines, algorithm in the spec.
- **escape's pools** (the ECS project, their milestone 1): no entity
  can hold a component until they land it. `arena2` and the engine
  tests say so and wait.

Read `ARCHITECTURE.md` before touching anything.

## Milestones

1. **The batcher.** Write `Push_Quad` from its spec. `arena` comes
   alive; `arena --frames 60` exits 0; ten TODO tests turn PASS (set
   `Milestone := 1` in `tests.adb`). Prove it: `gnatprove --mode=all`
   on `Yarlib.Batch`.
2. **Text.** A bitmap font baked as an Ada constant, `Draw_Text`,
   `Measure_Text`, and the console drawn on screen (toggle with a
   key) instead of read from stdin. First texture atlas.
3. **Images.** A QOI decoder (150 lines, lossless), `Load_Texture
   (file)`, and `texture NAME FILE` in the console so scenes reference
   real sprites.
4. **Shapes, collision, animation.** Circles and polygons as fans;
   `Check_Collision_Recs`; a `Collide` system with a spatial hash; an
   `Animate` system over sprite sheets; tweens. The Draw `Alpha`
   actually used for interpolation.
5. **Audio.** `Load_Sound`, `Play_Sound`, WAV, mixing in a platform
   callback. Extends the platform seam; `null` stays honest.
6. **The portal port.** When portal lands, `ports/platform/portal` is
   a second body. No game changes.
7. **The editor.** See `editor/README.md`. After hot reload and the
   console, see how much of it you still need.

## Build

Six [Alire](https://alire.ada.dev) crates. The root pins bedrock by
URL; the engine pins escape by URL; the others pin their parent by
path. Each picks its ports with `gpr-set-externals`; the library
defaults to `null`/`software`.

```
alr build                                        # library
cd tests    && alr build && ./bin/tests          # null platform, software renderer
cd showcase && alr build && ./bin/arena          # SDL3 + OpenGL
cd engine   && alr build                         # fetches escape from GitHub
cd engine/tests    && alr build && ./bin/engine_tests
cd engine/showcase && alr build && ./bin/arena2 arena.scene
alr with gnatprove && alr exec -- gnatprove -P yarlib.gpr --mode=flow
```

By hand: `gprbuild -P yarlib.gpr -XYARLIB_PLATFORM=sdl3 -XYARLIB_RENDERER=opengl`.

Contracts are checked at runtime (`-gnata`). Warnings are errors.

### SDL3

Only the two showcases and the editor need it.

- Windows (MSYS2, the toolchain Alire uses): `pacman -S mingw-w64-ucrt-x86_64-SDL3`
- macOS: `brew install sdl3`
- Fedora: `dnf install SDL3-devel`. Debian trixie, Ubuntu 25.04+:
  `apt install libsdl3-dev`. Ubuntu 24.04: from source, see
  `.github/workflows/ci.yml`; five minutes.

OpenGL comes with the OS driver; nothing to install. The link line is
picked per OS in `yarlib.gpr` (`-lGL`, `-lopengl32`, or the OpenGL
framework on macOS); Alire sets `YARLIB_OS`. Building without Alire on
macOS or Windows: pass `-XYARLIB_OS=macos` or `-XYARLIB_OS=windows`.

Windows clones made before `.gitattributes` existed have CRLF sources,
which the style checks reject. Fix an existing clone once (commit or
stash local work first):

```
git pull
git rm --cached -r -q .
git reset --hard
```

## Driving it from anything

```
arena --record run.rec            play; every input is written down
arena --replay run.rec            same game, no hands, same result
arena --frames 300 --replay t.rec deterministic; exit code = pass/fail; shot.png
arena2 -c "spawn boss 400 100 64 64" -c "set boss velocity 0 80" -c "scene save level2.scene"
```

A `.rec` reproduces a play session, so it can be attached to a bug
report and replayed. A `.scene` is a level. `-c` runs a console line
before the loop starts; there is no on-screen console until milestone
2, and no scripting language: the console verbs and the scene grammar
are the whole vocabulary.

## Rules of the road

- A game withs `Yarlib`, `Core`, `Shapes`, `Textures`, `Game_Loop`,
  `Replay`, `Console`, and `Engine.*`. Never `Batch`, `Raster`,
  `Platform`, `Renderer`. CI greps the showcases and
  the editor.
- Nothing in `src/` names SDL, OpenGL, X11, Win32, adi2 or escape. C
  lives in `ports/` only; escape lives in `engine/` only. CI greps.
- No type that bedrock has is declared again here. If yarlib needs a
  fundamental type bedrock lacks, that is a conversation with the
  coordinator, not a local declaration.
- A renderer port is dumb: bind texture, draw arrays. Transforms, the
  camera, atlases, sorting happen in the batch or above, on the CPU.
- `null`/`software` is the oracle. If `sdl3`/`opengl` shows something
  different, the port is wrong.
- `Update` is a function of `Dt`, the input state and the game's own
  state. Nothing else. If a replay diverges, that rule was broken.

See `CONTRIBUTING.md` for the fork workflow.

## Contact

Olivier Henley, GAP Coordinator, AdaCore. Weekly meeting, plus the
project Discord.

## License

Apache-2.0. See `LICENSE`. The SDL3 binding in `ports/platform/sdl3`
follows the shapes in [adi2](https://github.com/ovenpasta/adi2)
(Apache-2.0).
