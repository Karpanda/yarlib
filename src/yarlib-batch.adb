package body Yarlib.Batch with SPARK_Mode is

   -----------
   -- Reset --
   -----------

   procedure Reset (B : in out Batch) is
   begin
      B.Vertex_Count := 0;
      B.Call_Count := 0;
   end Reset;

   ---------------
   -- Push_Quad --
   ---------------

   procedure Push_Quad
     (B : in out Batch; Tex : Texture_Id; P, UV : Quad_Corners; C : Color; Ok : out Boolean)
   is
      New_Call : Boolean;
   begin
      --  make sure 6 vertices will fit
      if B.Vertex_Count > Max_Vertices - 6 then
         Ok := False;
         return;
      end if;

      --  new call if the texture changed
      New_Call :=
        B.Call_Count = 0
        or else B.Calls (B.Call_Count).Tex /= Tex;

      if New_Call then
         --  check if array is full
         if B.Call_Count = Max_Calls then
            Ok := False;
            return;
         end if;

         B.Call_Count := B.Call_Count + 1;
         B.Calls (B.Call_Count) :=
           (Tex   => Tex,
            First => B.Vertex_Count + 1,
            Count => 0);
      end if;

      --  append two triangles: (1,2,3 and 1,3,4)
      for I in 1 .. 6 loop
         declare
            Corner : constant Integer :=
              (case I is
                 when 1 => 1,
                 when 2 => 2,
                 when 3 => 3,
                 when 4 => 1,
                 when 5 => 3,
                 when 6 => 4);

            Index : constant Vertex_Index :=
              B.Vertex_Count + Vertex_Index (I);
         begin
            B.Vertices (Index) :=
              (X => P (Corner).X,
               Y => P (Corner).Y,
               U => UV (Corner).X,
               V => UV (Corner).Y,
               C => C);
         end;
      end loop;

      --  update counts
      B.Vertex_Count := B.Vertex_Count + 6;
      B.Calls (B.Call_Count).Count :=
        B.Calls (B.Call_Count).Count + 6;

      Ok := True;
   end Push_Quad;

end Yarlib.Batch;
