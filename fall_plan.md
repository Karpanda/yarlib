# yarlib: fall plan, three people

Oct 21 to Dec 11, 2026. Seven weeks of work, one week of demo and
report. This is a tutorial as much as a schedule: every week says what
to understand before touching the code, what each person builds, how
you know it is done, and how to describe the problem to an AI agent
when you are stuck. Read it once end to end, then one week at a time.

You are three. Call yourselves A, B and C now and write the names in
this file. The tracks are:

- **A: the funnel.** The batcher, its SPARK proof, the camera and
  interpolation, collision.
- **B: text.** A bitmap font, the texture atlas, `Draw_Text`, the
  on-screen console, sprite-sheet animation.
- **C: images and shapes.** A QOI decoder, `Load_Texture` from a
  file, circles and polygons, the showcase game.

Every track lands in `src/` and is visible in `showcase/arena`. None of
them touches `engine/`. That is on purpose: see "What you are not
waiting for" below.

## What you are not waiting for

Two sibling projects show up in this repository: escape (the ECS,
another team) and portal (the platform library, another team).
Neither is ready, and neither blocks you.

**escape** is a dependency of the `engine/` crate only. Nothing in
`src/` names it; CI greps for that. Milestones 1 through 5 in the
README (batcher, text, images, shapes and collision and animation,
audio) all live in `src/` and `ports/`, and are all exercised by
`showcase/arena` and `tests/`, which do not fetch escape at all.
The `engine/` code that uses escape is already written in the seed
and gated on escape's milestone 1 (component pools); when that lands,
`arena2` and `engine/tests` turn green with no change on your side.
If escape never lands this semester, the deliverable is still a
complete 2D library plus a working showcase game. So for the fall:
do not run `cd engine && alr build`, it is the one line in the README
that fetches escape, and you have no use for it yet.

**portal** is a second body for the platform seam, `Yarlib.Platform`.
The first body, `ports/platform/sdl3`, is the one you run on, and it
is a real backend, not a stopgap. Nothing you write in milestones 1
through 5 names SDL or portal; the body is picked by the gpr external
`YARLIB_PLATFORM`. If portal lands, someone writes
`ports/platform/portal` from the same spec (about 200 lines, the size
of the sdl3 body) and flips the external. If it does not, nothing is
missing.

Where the README's milestone 4 says "a `Collide` system" and "an
`Animate` system", those systems are engine-layer (escape) things.
This fall you build the same functionality as plain library packages
in `src/` (`Yarlib.Collision`, `Yarlib.Animation`) and use them from
`arena` with plain records. Turning them into escape systems is a
thin step for whoever has escape in hand, this spring or next cohort.

## The one idea behind everything: the funnel

Before week 1, every one of you must be able to explain this out loud
without notes.

Every visible thing in yarlib is a quad: four screen-space corners,
four texture coordinates, one colour, one texture id. `Shapes` builds
quads on the white 1x1 texture (id 0). `Textures` builds quads on a
real texture. Both call `Core.Submit`, which applies the camera if one
is active, then calls `Batch.Push_Quad`. The batch is an array of
vertices (six per quad, two triangles) and an array of draw calls
(one per run of consecutive quads with the same texture). At
`End_Drawing`, `Core.Flush` hands the batch to `Renderer.Draw`, and
the renderer port does the dumbest possible thing: for each call, bind
its texture, draw its vertex range.

Consequences you will use every week:

- The GPU port never gets smarter. Camera, atlas, sorting, culling
  happen in or above the batch, on the CPU, portably.
- A thousand sprites on one texture is one draw call. Text is cheap
  only if all glyphs live on one texture (that is the atlas).
- The `software` renderer is the oracle. It draws the same batch into
  a Bedrock image with `Yarlib.Raster`. Tests read pixels from it with
  no window. If `opengl` shows something different from `software`,
  the port is wrong, never the library.
- `Push_Quad` is the only placeholder in the library. Nothing draws
  until it is written. That is week 1.

Read, in this order, before week 1: `README.md`, `ARCHITECTURE.md`,
`src/yarlib-batch.ads` (the whole header comment), `src/yarlib-core.ads`,
`showcase/src/arena_game.adb`.

## Rules that will bite you

- `Update (Dt)` is a function of `Dt`, the input state and the game's
  own state. No wall clock, no unseeded random. If `--replay` gives a
  different result than `--record`, you broke this rule, and the
  replay machinery just told you where.
- A game withs `Yarlib`, `Core`, `Shapes`, `Textures`, `Game_Loop`,
  `Replay`, `Console`. Never `Batch`, `Raster`, `Platform`, `Renderer`.
  CI greps `showcase/src`. If the game needs something it cannot get
  through the API, that is a missing library feature; add it to
  `src/`, never reach past.
- No type that bedrock has is declared again in yarlib. `Vector2`,
  `Rectangle`, `Color`, `Key`, `Event`, `Image` come from bedrock. If
  you need a fundamental type bedrock lacks, ask the coordinator.
- Nothing in `src/` names SDL, OpenGL or C. `Interfaces.C` and
  `pragma Import` are allowed in `ports/` only. CI greps.
- `tests/src/tests.adb` has a `Milestone` constant. Checks tagged
  above it print TODO instead of FAIL. When you land a milestone,
  raise the constant in the same commit; CI then holds you to it.
- `arena --frames 60` exits 1 while the batcher is a placeholder and
  CI tolerates that. At milestone 1 you flip CI to require exit 0
  (the comment in `.github/workflows/ci.yml` says where).
- Build in the development profile day to day. Before pushing, build
  with `alr build --validation`: warnings are errors there, and that
  is what CI runs. Format with `gnatpp` rather than fighting style
  checks by hand.
- Do not weaken a contract to make something pass. If a contract is
  wrong, fix it on its own with the reasoning in the commit message
  and bring it to the meeting.

## How to ask an AI agent

You will use one. Used well it is a fast pair; used badly it writes C
in Ada syntax and reaches past the seams. The difference is entirely
in how you describe the problem. Every question you ask must contain:

1. **Where.** The package and file. Paste the spec header comment:
   it is the design, written for exactly this purpose.
2. **The invariant.** Name it. For the batch it is `Well_Formed`;
   paste the expression. For the loop it is "Update is a function of
   Dt, input and state". For the layering it is "src/ names no library
   but bedrock".
3. **What you observe and what you expected.** The test name, the
   PASS/FAIL/TODO line, the pixel you read and the pixel you wanted.
4. **What you are not allowed to do.** Say it explicitly: no new
   types for things bedrock has, no `with Yarlib.Batch` from a game,
   no `Interfaces.C` in `src/`, no `access` where an array index does,
   no exceptions where an `Ok : out Boolean` is the convention here.
5. **The check.** How you will know the answer is right: which test,
   which pixel, which gnatprove line.

A template:

```
I am working on yarlib, an Ada 2022 2D game library. Package
<Yarlib.X>, file <src/yarlib-x.ads>. Here is the spec header:
<paste>. The invariant I must keep is <name>: <paste>. I am trying to
<goal>. Currently <observation>; I expected <expectation>. Constraints:
no heap, no access types unless the seed already uses them here, no
redeclaring bedrock types, Ok out parameters instead of exceptions,
SPARK_Mode on this unit. I will check the answer by <test or proof>.
```

Then read the answer as a reviewer, not a consumer. If it adds a
`with` the rules forbid, a tagged type, an exception, or a
`'Unchecked_Access`, it did not understand the design; fix the
question, not the code.

## Schedule

| Week | Dates          | A: funnel                       | B: text                          | C: images and shapes            |
| ---- | -------------- | ------------------------------- | -------------------------------- | ------------------------------- |
| 1    | Oct 21 to 25   | Push_Quad (everyone)            | Push_Quad (everyone)             | Push_Quad (everyone)            |
| 2    | Oct 26 to Nov 1| prove Batch                     | font constant, atlas             | QOI decoder                     |
| 3    | Nov 2 to 8     | Alpha interpolation in arena    | Draw_Text, Measure_Text          | Load_Texture (file), console verb |
| 4    | Nov 9 to 15    | Check_Collision_Recs, Yarlib.Collision | on-screen console          | circles, polygons, lines        |
| 5    | Nov 16 to 22   | spatial hash                    | sprite sheets, Yarlib.Animation  | arena: sprites, collisions, HUD |
| 6    | Nov 23 to 29   | light week (Thanksgiving)       | light week                       | light week                      |
| 7    | Nov 30 to Dec 6| integration, proof summary      | integration, tweens              | integration, CI screenshot test |
| 8    | Dec 7 to 11    | demo and report                 | demo and report                  | demo and report                 |

Weekly meeting with the coordinator: book it through his calendar
link. Come with the diff open on your fork.

---

## Week 1 (Oct 21 to 25): the batcher

**Goal.** `arena` draws. Everyone writes `Push_Quad`; the team picks
one, the other two review it line by line.

**Understand first.** Read `src/yarlib-batch.ads` until you can
answer, without looking: why six vertices per quad and not four plus
an index buffer (the comment says: simpler to prove, GPU does not
care at this size). What forces a new draw call (a texture change,
because a call binds one texture). What `Well_Formed` says, clause by
clause: every call is non-empty, a whole number of quads, starts
inside the vertex array, fits in it, starts exactly where the previous
call ended, differs in texture from the next one, and the last call
ends exactly at `Vertex_Count`. Why `Push_Quad` refuses with
`Ok = False` instead of flushing (the batch does not know the GPU;
`Core.Submit` flushes and retries, look at it).

**Do, each of you alone.** Write `Push_Quad` in
`src/yarlib-batch.adb` from the four-step algorithm in the spec
header. It is about thirty lines. Delete the `Dropped` counter and its
report in `Core.Close_Window`. Build with `alr build`, then
`cd tests && alr build && ./bin/tests`. Set `Milestone := 1` in
`tests/src/tests.adb`. Ten TODO lines must turn PASS.

**Do, together.** Compare the three versions. Pick one. Run
`cd showcase && alr build && ./bin/arena`. Blocks, a spinning
checkerboard sprite, a ship you steer, a line to the mouse. Run
`./bin/arena --frames 60`; it must now exit 0 and write `shot.png`.
Flip the CI step so exit 0 is required (the comment in `ci.yml`
marks the line). Commit on the fork with the Milestone change.

**Done when.** `tests` prints 0 FAIL and 0 TODO for milestone 1 items,
`arena --frames 60` exits 0, CI is green with the flipped step.

**Trap.** Winding order. P1 P2 P3 then P1 P3 P4, exactly as the
spec says. The software rasterizer does not care (the test "winding
does not matter" proves it), but a GL port with face culling someday
will, and the atlas work in week 3 assumes it.

**Ask an agent like this.** "Package Yarlib.Batch, SPARK_Mode on.
Here is the spec header with the ALGORITHM section: <paste>. Here is
Well_Formed: <paste>. My Push_Quad passes the tests 'push one quad'
and 'same texture, same call' but fails 'texture change starts a
call': Calls (2).First is 7, expected 13. Walk me through step 2 of
the algorithm against my code: <paste body>. I may not add fields to
Batch or change the spec."

---

## Week 2 (Oct 26 to Nov 1)

### A: prove the batch

**Goal.** `gnatprove --mode=all` proves `Yarlib.Batch` with no
unproved check.

**Understand first.** The contract is already written: `Pre =>
Well_Formed (B)`, `Post => Well_Formed (B) and then (...)`. Proof
means the prover can show, from the body, that the post holds on every
path. Where it fails, it will be one of: an array index it cannot
bound, a loop it cannot summarise (there is no loop in `Push_Quad`,
good), or an "and then" clause of `Well_Formed` it cannot see from the
assignments. Read the SPARK User's Guide sections on postconditions
and on "How to investigate unproved checks". Run with
`--report=all` to see what it did prove.

**Do.** `alr with gnatprove`, then
`alr exec -- gnatprove -P yarlib.gpr --mode=all -u yarlib-batch.adb
--report=all`. Work the unproved checks one at a time. The tools you
have: `pragma Assert` placed between the steps of the algorithm to
tell the prover intermediate facts (keep the ones that are needed,
delete the others), `--level=2` if level 1 is not enough, and
reordering assignments so each `Well_Formed` clause is obviously
re-established. Expect the "adjacent calls differ in texture" clause
and the "last call ends at Vertex_Count" clause to need an assert
each.

**Done when.** The gnatprove summary for `yarlib-batch.adb` says
everything is proved, and the CI SPARK step is upgraded from
`--mode=flow` to `--mode=all` for that unit (keep flow for the rest).

**Ask an agent like this.** "SPARK, GNAT 2022 toolchain. Unit
Yarlib.Batch, here is the full spec and body: <paste>. gnatprove
--mode=all --level=1 reports: <paste the exact message with line
numbers>. Which clause of Well_Formed is it, what fact does the
prover lack at that point, and what is the smallest pragma Assert
that supplies it? Do not change the contract or the types."

### B: a bitmap font as an Ada constant, and the atlas

**Goal.** A 128x64 texture holding 96 printable ASCII glyphs, built
at startup from an Ada constant, with a function that gives the
source rectangle of any character.

**Understand first.** Text in a 2D library is sprites. Each glyph is
a small rectangle cut from one texture (the atlas); drawing a string
is one quad per glyph, all on the same texture, so a whole string is
one draw call. The font itself is just bits: an 8x8 font is 8 bytes
per glyph, one bit per pixel. Baked as an Ada constant array it needs
no file, no loader, and works on a bare-metal target later. Sources:
dhepper's `font8x8` (public domain) is the usual pick; or draw your
own 5x7 in a comment and transcribe it. Keep the licence line in the
file.

**Do.** New package `Yarlib.Font` in `src/`, SPARK-friendly (plain
arrays, no access): `Glyph_Width`, `Glyph_Height` constants; a
constant `Bits : array (Character range ' ' .. '~') of Glyph_Rows`;
a function `Build_Atlas return Bitmap` that paints every glyph into
one Bedrock image, white on transparent, 16 glyphs per row; a
function `Source (C : Character) return Rectangle` giving the glyph's
texel rectangle in that atlas. Write a test in `tests.adb`: build the
atlas, check that the pixel at the top-left of 'A' is what the bits
say, and that `Source ('B').X = Source ('A').X + Glyph_Width`.

**Done when.** The test passes on `null`/`software`. You can
`Load_Texture (Build_Atlas)` and `Draw_Texture` it in arena and see a
grid of letters.

**Trap.** Transparent background means alpha 0, and the software
rasterizer blends straight alpha; the GL port must do the same
(`glBlendFunc (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA)`). If letters
come out in boxes on screen but not in the test, it is the GL port's
blend state, and that is a port bug, not a font bug.

**Ask an agent like this.** "Ada 2022, no heap. I have a constant
array of 8x8 bitmaps indexed by Character. I want a function that
returns a Bedrock.Buffers.Image (API: Make (W, H, Fill), Set (Img, X,
Y, Color)) with the 96 glyphs laid out 16 per row. Give me the
arithmetic for glyph (Character'Pos (C) - 32) to (column, row) to
(pixel X, pixel Y), and the test I would write to catch an off-by-one
in it."

### C: a QOI decoder

**Goal.** `Yarlib.QOI.Decode (Bytes) -> Bitmap`, pure, bounded, with
SPARK_Mode on and no unproved flow checks.

**Understand first.** QOI is a one-page lossless image format
(qoiformat.org, read the spec, it is short). A 14-byte header, then a
stream of chunks: run-length, index into a 64-entry colour cache,
small difference from the previous pixel, luma difference, full RGB,
full RGBA. The decoder is a loop over bytes with a previous pixel, a
64-entry array and a write cursor. About 150 lines. It is pure: bytes
in, pixels out, no file, no C. That is why it lives in `src/` and
why a bare-metal port can decode a sprite from flash with the same
code.

**Do.** New package `Yarlib.QOI` in `src/`. `type Byte_Array is array
(Positive range <>) of Interfaces.Unsigned_8` (check bedrock first;
if it already has a byte array type, use that, do not redeclare).
`procedure Decode (Data : Byte_Array; Img : out Bitmap; Ok : out
Boolean)` with a precondition on `Data'Length >= 14`. Hash for the
index is `(r * 3 + g * 5 + b * 7 + a * 11) mod 64`, exactly as the
spec says. Test fixtures: write a 30-line Python encoder (or use the
reference `qoiconv`) to turn a 4x4 checkerboard PNG into `.qoi`,
paste the bytes as a constant in the test, decode, and compare every
pixel to the expected checkerboard. Add a second fixture that
exercises runs and the index (a solid 8x8 does both).

**Done when.** Both fixture tests pass on `software`;
`gnatprove --mode=flow` is clean on the unit.

**Trap.** The QOI_OP_RGB tag is `0xFE` and QOI_OP_RGBA is `0xFF`; they
collide with the top two bits of QOI_OP_RUN (`11xxxxxx`), so check
the 8-bit tags first, then the 2-bit ones. Every decoder bug report
ever is this.

**Ask an agent like this.** "I am writing a QOI decoder in SPARK Ada,
no heap, output into a pre-sized image via Set (Img, X, Y, Color).
Here is my chunk dispatch: <paste>. The 4x4 checkerboard fixture
decodes correctly but the solid 8x8 fixture gives garbage after pixel
3. Here are the fixture bytes: <paste>. Which chunk am I
misinterpreting? Quote the spec sentence."

---

## Week 3 (Nov 2 to 8)

### A: interpolation in the showcase

**Goal.** `Draw (Alpha)` in arena actually uses `Alpha`, and motion
is smooth at any frame rate.

**Understand first.** `Yarlib.Game_Loop` runs `Update` at a fixed
`Dt` zero or more times per frame, then `Draw` once with `Alpha` in
0 .. 1 saying how far into the next step the frame falls. Read the
"Fix Your Timestep" article (Glenn Fiedler). If `Draw` ignores
`Alpha`, objects visibly stutter when the display rate and the update
rate do not divide evenly. The fix is in the game, not the library:
keep the previous position of each moving thing, draw at
`Prev + (Pos - Prev) * Alpha`.

**Do.** In `arena_game.adb`, add `Prev_Pos` to `Block` and
`Prev_Ship`; at the top of `Update`, copy current into previous; in
`Draw`, interpolate. Then a test: in `tests.adb`, run the loop
headless and check that in headless mode `Alpha` is what the spec
says it is (read `yarlib-game_loop.adb` to find out; one step per
frame means a fixed value). Then set the window to vsync-off if your
driver allows and watch a block cross the screen: no stutter.

**Done when.** The replay test still passes (interpolation is in
`Draw`, so it cannot change state; if the replay test breaks, you
interpolated in `Update`, which is wrong). Visual check at the
meeting.

### B: Draw_Text and Measure_Text

**Goal.** `Draw_Text (Text, X, Y, Size, Color)` and
`Measure_Text (Text, Size) return Integer`, raylib's `rtext` surface.

**Understand first.** A new package `Yarlib.Text` that withs
`Yarlib.Core`, `Yarlib.Textures`, `Yarlib.Font`. On first use it
uploads the atlas once (`Load_Texture (Build_Atlas)`), stores the
`Texture` in a package variable. `Draw_Text` walks the string and
calls `Draw_Texture_Pro` once per glyph with `Source (C)` as the
source rectangle and a destination scaled by `Size / Glyph_Height`.
All glyphs are on one texture, so the batch merges them into one
draw call; verify that with a test that pushes a 40-character string
and checks `Call_Count` did not grow by 40 (you can read
`Core.Default.all.B` from the test, tests are allowed below the API).

**Do.** Package, both procedures, Context and flat forms like every
other API package. Test: draw "A" at (0, 0) size 8 on `software`,
read the pixel the font bits say is set, compare to the colour.
Measure: `Measure_Text ("abc", 16) = 3 * 8 * 2`.

**Done when.** Arena shows an FPS counter and the block count in the
top-left, and the pixel test passes.

**Trap.** Nearest-neighbour sampling with an atlas: a destination
rectangle that lands on half pixels will bleed the neighbouring
glyph's column. Inset the source rectangle by half a texel, or keep
destinations on integer pixels for integer scale factors. The test
will catch the bleed if you check a pixel on the glyph's right edge.

### C: Load_Texture from a file, and a console verb

**Goal.** `Load_Texture (File : String) return Texture` and the
console line `texture NAME FILE`.

**Understand first.** The decoder is pure and lives in `Yarlib.QOI`.
Reading the file is the impure part and it belongs one layer up, in
`Yarlib.Textures`, next to the existing `Load_Texture (Img)`. Keep
that split: whoever ports yarlib to a board with sprites in flash
replaces the file read, not the decoder. For reading bytes,
`Ada.Streams.Stream_IO` into a `Byte_Array` sized from the file
length; `Ada.Directories.Size` gives it. Failure is `Ok = False` or,
following the seed's convention for `Load_Texture`, `Program_Error`
with a clear message; look at how the existing overload fails and do
the same.

**Do.** The overload in `Yarlib.Textures`. A console handler
`texture NAME FILE` in `arena_game.adb` that loads and stores the
texture under a name (a small bounded table of name to Texture; a
plain array of 32 entries is enough), and `sprite NAME X Y` that
draws it. Test: write the 4x4 checkerboard fixture to a temp file
from the test, load it, draw it, read a pixel.

**Done when.** `arena -c "texture ship ship.qoi" -c "sprite ship 100 100"`
shows the sprite, and the test passes.

---

## Week 4 (Nov 9 to 15)

### A: Check_Collision_Recs and Yarlib.Collision

**Goal.** A pure, SPARK-proved collision package.

**Understand first.** Axis-aligned rectangle overlap is four
comparisons. The point is not the arithmetic, it is the contract:
`Check_Collision_Recs (A, B)` is symmetric, a rectangle collides with
itself, and two rectangles that touch on an edge do or do not collide
by a rule you choose and write down in the spec comment. Then
`Get_Collision_Rec (A, B)` returns the overlap rectangle, with the
post that it is contained in both. These are the raylib names; keep
them.

**Do.** Package `Yarlib.Collision` with SPARK_Mode, functions over
`Bedrock.Rectangle`: `Check_Collision_Recs`, `Check_Collision_Point_Rec`,
`Check_Collision_Circles`, `Check_Collision_Circle_Rec`,
`Get_Collision_Rec`. Expression functions where possible, so the
prover sees the body. Tests for the edge-touch rule and for symmetry.
`gnatprove --mode=all` on the unit.

**Done when.** Proved, tested, and arena blocks change colour when
they overlap the ship.

### B: the on-screen console

**Goal.** A key toggles a console panel; typed lines go to
`Console.Execute`; responses scroll above the input line.

**Understand first.** Text input is the subtle part. SDL has a text
input event with Unicode characters. Do not use it. `Yarlib.Replay`
records key events, mouse events, resize and quit, nothing else; a
console driven by SDL text events would be invisible to `--record`,
untestable from `Inject`, and would need the sdl3 port to grow a new
event kind. Instead, build the console's input from `Key` events:
letters, digits, space, minus, backspace, enter. That is enough for
every verb in the grammar, and a `.rec` can then drive the console
in a test. The panel itself is `Draw_Rectangle` with alpha plus
`Draw_Text` per line, drawn last in `Draw` so it sits on top.

**Do.** Package `Yarlib.Console_View` (withs `Core`, `Shapes`, `Text`,
`Console`): a bounded ring of the last N response lines, an input
buffer, `Toggle`, `Handle_Input (Ctx)` called from `Update`,
`Draw (Ctx)` called at the end of `Draw`. Hook it into arena. Test:
inject the key events for `l i s t Enter` through `Core.Inject`, run
a frame, check that the ring's last line starts with "ok".

**Done when.** In arena, the grave key opens the console, `spawn 100
100 20` adds a block, `help` lists verbs, and the injected-keys test
passes.

### C: circles, polygons, thick lines

**Goal.** raylib's remaining `rshapes` primitives: `Draw_Circle`,
`Draw_Circle_Lines`, `Draw_Triangle`, `Draw_Poly`, `Draw_Ring`.

**Understand first.** Everything is a quad. A circle is a fan of N
triangles around the centre. The batch has no triangle entry point,
and it should not get one (`Well_Formed` says "whole quads"). So a
triangle is a quad whose fourth corner repeats the third: the second
triangle of the quad is degenerate (zero area) and the rasterizer
skips it (test "degenerate triangle is a no-op" already covers that).
Twelve to thirty-six segments depending on radius; choose N from the
radius so big circles are round and small ones are cheap. Write that
rule in the spec comment.

**Do.** Add to `Yarlib.Shapes`, Context and flat forms. One helper
`Submit_Triangle` in the body that builds the degenerate quad. Tests
on `software`: `Draw_Circle (8, 8, 6, Red)` on a 16x16 context, the
centre pixel is red, the corner (0, 0) is not.

**Done when.** Tests pass and arena draws the ship as a circle with a
ring around it.

**Trap.** Degenerate quads double the vertex count of a fan. Fine for
circles. If someone later wants thousands of particles as triangles,
the right move is a `Push_Triangle` with its own `Well_Formed`
clause, with a proof, not a game that bypasses the batch.

---

## Week 5 (Nov 16 to 22)

### A: a spatial hash

**Goal.** Broad-phase collision for a few thousand rectangles without
N squared pair tests.

**Understand first.** A uniform grid of cells; each rectangle is
inserted into every cell it overlaps; candidate pairs are rectangles
sharing a cell. Bounded version: a fixed array of cells, each a fixed
array of entries, `Ok = False` when a cell is full. No heap, no
access. Generic over the entry type is tempting; keep it to
`Positive` indices into the caller's array, which is what the engine
systems will need anyway (escape entity ids are integers).

**Do.** `Yarlib.Collision.Grid`: `Clear`, `Insert (Id, R, Ok)`,
`Query (R, Out : out Id_List)` with duplicates removed. Test: 1000
random rectangles, compare `Query` results against brute force. Then
a stress target in arena: `spawn` 2000 blocks via a console loop
and check that the frame time stays under 16 ms on your machine with
collisions on.

**Done when.** The brute-force comparison test passes; the stress
number is in the commit message.

### B: sprite sheets and Yarlib.Animation

**Goal.** `Draw_Texture_Pro` with a source rectangle from a frame
index, and a small animation clock.

**Understand first.** A sprite sheet is a texture with frames in a
grid. An animation is `(Frame_Width, Frame_Height, Frame_Count,
Frames_Per_Second)` plus a time accumulator. `Frame_Of (Anim, T)`
returns the source `Rectangle`. Pure, SPARK, no state in the library;
the game owns the clock (in `Update`, so replay reproduces it).

**Do.** Package `Yarlib.Animation`: a record type, `Advance (A, Dt)`,
`Source (A) return Rectangle`. Test the arithmetic for a 4x2 sheet at
10 fps: after 0.35 s the frame index is 3; after 0.85 s it wrapped to
0 (or clamped, if you add a `Loop` flag; write which).

**Done when.** Arena has one animated sprite from a QOI sheet C made.

### C: the showcase game

**Goal.** `arena` uses everything: QOI sprites, text HUD, circles,
collisions, the on-screen console.

**Do.** Make `arena` a small game rather than a demo: the ship
collects blocks, a score in the HUD, blocks bounce off each other via
A's grid, an animated sprite from B's package. Keep `Update` a
function of `Dt`, input and state, so `--record` and `--replay` still
agree. Add a replay-driven gameplay test: record ten seconds of you
collecting three blocks, commit the `.rec`, and assert the score in
`tests.adb` after replaying it headless.

**Done when.** The `.rec` test passes in CI on `software`.

---

## Week 6 (Nov 23 to 29): light week

US Thanksgiving. Each of you: finish what slipped, write the comment
headers you skipped, run `gnatpp`, make CI green. No new features.

If you are ahead: milestone 5, audio. `Load_Sound`, `Play_Sound`, WAV
parsing (pure, like QOI, in `src/`), mixing in a platform callback
(extends `Yarlib.Platform` with `Open_Audio`, `Queue_Samples`; the
`null` body stays honest and plays nothing). That extends the seam,
so bring the spec to the meeting before writing the sdl3 body.

---

## Week 7 (Nov 30 to Dec 6): integration

- A: proof summary. Run `gnatprove --mode=all` on `Batch`,
  `Collision`, `QOI`, `Animation`, `Font`. One table in the README:
  unit, checks, proved, remaining, with a sentence per remaining one.
- B: tweens (`Ease_In_Out` and friends as pure functions over
  `Scalar`) used for the HUD score counting up. Small, visible, and a
  good last SPARK unit.
- C: a CI screenshot test. `arena --frames 120 --replay demo.rec`
  writes `shot.png`; CI compares it byte for byte to a committed
  `expected.png` produced on `software`. Any rendering regression now
  fails CI. (`software` is the oracle; the GL window is not what CI
  compares.)
- Everyone: raise `Milestone` in `tests.adb` to the last one you
  landed and check that 0 TODO remain at that number.

---

## Week 8 (Dec 7 to 11): demo and report

**Demo, ten minutes.** `arena` from a cold clone: `alr build`,
`cd showcase && alr build && ./bin/arena`. Play it. Open the console
and spawn things. Quit, `--replay` the session you just recorded,
same result. Show the CI page green with the screenshot test. Show
the gnatprove table.

**Report.** Keep it short and specific:

1. What the seed had on Oct 21, what the fork has on Dec 11, as the
   README's "What is in the seed" table with a column for who did
   what.
2. The funnel, explained in your own words with one diagram.
3. Three decisions you made and why (edge-touch collision rule,
   console input from keys instead of SDL text, degenerate quads for
   triangles, whatever yours were).
4. The proof table and what each remaining check would take.
5. What you would do with escape and portal if they landed tomorrow:
   which of your packages become engine systems, what the portal body
   needs from `Yarlib.Platform` that the sdl3 body shows.

That last section is the spring plan, and it is the sentence the
coordinator will use to pitch the integration capstone next year.