--  The batch: every drawn thing is a textured, coloured quad, and every
--  quad goes through here. raylib calls this rlgl. PLACEHOLDER in the
--  seed: Push_Quad reports Ok = False, so nothing is drawn until
--  milestone 1. The window opens, Clear_Background works, and the
--  console counts what was dropped.
--
--  Why a batch: a GPU draws a million triangles in one call and ten
--  thousand calls of one triangle each at a crawl. So we collect
--  vertices in CPU memory during the frame and hand the GPU a few big
--  arrays at End_Drawing. The only thing that forces a new draw call
--  is a change of texture (a call binds one texture), which is why
--  Draw_Call carries a Texture_Id and a vertex range.
--
--  Layout: six vertices per quad (two triangles, no index buffer:
--  simpler to prove, and the GPU does not care at this size). Calls
--  are contiguous, in order, and tile the vertex array exactly. That
--  is Well_Formed, and it is what lets the GPU port loop over calls
--  blindly.
--
--  ALGORITHM (Push_Quad):
--    1. If Vertex_Count + 6 > Max_Vertices: Ok := False, return.
--       (Core flushes and calls again; do not flush from here, the
--       batch does not know the GPU.)
--    2. If Call_Count = 0, or Calls (Call_Count).Tex /= Tex:
--       if Call_Count = Max_Calls: Ok := False, return;
--       else Call_Count += 1; Calls (Call_Count) := (Tex, First =>
--       Vertex_Count + 1, Count => 0).
--    3. Append the six vertices, in this order so both triangles wind
--       the same way: P1 P2 P3, P1 P3 P4, each with its UV and the
--       quad's colour. Vertex_Count += 6; Calls (Call_Count).Count += 6.
--    4. Ok := True.
--  That is the whole milestone 1, and everything on screen depends on
--  it. Then prove it: Well_Formed is the post of Push_Quad and Reset.
--
--  Later milestones extend this file, not bypass it: a texture atlas
--  (so text and sprites share one call), a transform stack for
--  Camera2D (apply the matrix here, on the CPU, per vertex; the GPU
--  port stays dumb), and a "sort by texture" mode for scenes where
--  draw order does not matter.

with Bedrock; use Bedrock;

package Yarlib.Batch with SPARK_Mode is

   Max_Quads    : constant := 8_192;
   Max_Vertices : constant := Max_Quads * 6;
   Max_Calls    : constant := 256;

   type Vertex is record
      X, Y : Scalar := 0.0;   --  screen pixels, origin top-left, y down
      U, V : Scalar := 0.0;   --  texture coordinates, 0 .. 1
      C    : Color := White;
   end record;

   type Vertex_Index is range 0 .. Max_Vertices;
   type Vertex_Array is array (Vertex_Index range 1 .. Max_Vertices) of Vertex;

   type Draw_Call is record
      Tex   : Texture_Id := White_Texture;
      First : Vertex_Index := 1;
      Count : Vertex_Index := 0;
   end record;

   type Call_Index is range 0 .. Max_Calls;
   type Call_Array is array (Call_Index range 1 .. Max_Calls) of Draw_Call;

   type Batch is record
      Vertex_Count : Vertex_Index := 0;
      Vertices     : Vertex_Array;
      Call_Count   : Call_Index := 0;
      Calls        : Call_Array;
   end record;

   function Well_Formed (B : Batch) return Boolean is
     ((for all I in 1 .. B.Call_Count =>
         B.Calls (I).Count > 0
         and then B.Calls (I).Count mod 6 = 0
         and then B.Calls (I).First >= 1
         and then B.Calls (I).First <= B.Vertex_Count
         and then B.Calls (I).Count <= B.Vertex_Count - B.Calls (I).First + 1
         and then (I = 1 or else B.Calls (I).First
                                = B.Calls (I - 1).First + B.Calls (I - 1).Count)
         and then (I = B.Call_Count or else B.Calls (I).Tex /= B.Calls (I + 1).Tex))
      and then (if B.Call_Count = 0 then B.Vertex_Count = 0
                else B.Calls (B.Call_Count).First + B.Calls (B.Call_Count).Count
                     = B.Vertex_Count + 1));
   --  Calls are non-empty, whole quads, contiguous, tile 1 .. Vertex_Count,
   --  and adjacent calls differ in texture.

   type Quad_Corners is array (1 .. 4) of Vector2;
   --  P1 top-left, P2 top-right, P3 bottom-right, P4 bottom-left, in
   --  screen space, after any rotation. UVs likewise.

   procedure Reset (B : in out Batch)
     with Post => B.Vertex_Count = 0 and then B.Call_Count = 0 and then Well_Formed (B);

   procedure Push_Quad
     (B : in out Batch; Tex : Texture_Id; P, UV : Quad_Corners; C : Color; Ok : out Boolean)
     with Pre  => Well_Formed (B),
          Post => Well_Formed (B)
                  and then (if Ok then B.Vertex_Count = B.Vertex_Count'Old + 6
                            else B.Vertex_Count = B.Vertex_Count'Old
                                 and then B.Call_Count = B.Call_Count'Old);
   --  Ok = False: full (vertices or calls). Caller flushes and retries.

end Yarlib.Batch;
