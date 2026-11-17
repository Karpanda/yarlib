with Ada.Numerics.Elementary_Functions;
with Bedrock.Buffers;
with Bedrock.Input;
with Bedrock.Screen; use type Bedrock.Screen.Pixels;
with Yarlib.Renderer;
with Yarlib.Platform;

package body Yarlib.Core is

   use type Batch.Call_Index;

   procedure Flush (Ctx : in out Context);

   The_Default : aliased Context;
   function Default return not null access Context is (The_Default'Access);

   ------------
   -- Camera --
   ------------

   function World_To_Screen (Cam : Camera2D; P : Vector2) return Vector2 is
      use Ada.Numerics.Elementary_Functions;
      Rad : constant Float := Float (Cam.Rotation) * Ada.Numerics.Pi / 180.0;
      Cs  : constant Scalar := Scalar (Cos (Rad));
      Sn  : constant Scalar := Scalar (Sin (Rad));
      D   : constant Vector2 := (P - Cam.Target) * Cam.Zoom;
   begin
      return (Cam.Offset.X + D.X * Cs - D.Y * Sn, Cam.Offset.Y + D.X * Sn + D.Y * Cs);
   end World_To_Screen;

   function Screen_To_World (Cam : Camera2D; P : Vector2) return Vector2 is
      use Ada.Numerics.Elementary_Functions;
      Rad : constant Float := Float (Cam.Rotation) * Ada.Numerics.Pi / 180.0;
      Cs  : constant Scalar := Scalar (Cos (Rad));
      Sn  : constant Scalar := Scalar (Sin (Rad));
      D   : constant Vector2 := P - Cam.Offset;
      U   : constant Vector2 := (D.X * Cs + D.Y * Sn, -D.X * Sn + D.Y * Cs);
   begin
      return Cam.Target + (U.X / Cam.Zoom, U.Y / Cam.Zoom);
   end Screen_To_World;

   -----------------
   -- Init_Window --
   -----------------

   procedure Init_Window (Ctx : in out Context; Width, Height : Positive; Title : String) is
      Ok : Boolean;
   begin
      Platform.Open (Width, Height, Title, Ok);
      if not Ok then
         raise Program_Error with "yarlib: cannot open a window";
      end if;
      Ctx.Width := Width;
      Ctx.Height := Height;
      Renderer.Init (Width, Height);
      Batch.Reset (Ctx.B);
      Ctx.In_State := (others => <>);
      Bedrock.Input.Clear (Ctx.Pending);
      Bedrock.Input.Clear (Ctx.Applied);
      Ctx.Frames := 0;
      Ctx.Open := True;
      Ctx.Last_Tick := Platform.Now;
      Ctx.FPS_Since := Ctx.Last_Tick;
   end Init_Window;

   function Window_Is_Open (Ctx : Context) return Boolean is (Ctx.Open);

   function Window_Should_Close (Ctx : Context) return Boolean is
     (not Ctx.Open or else Ctx.In_State.Quit_Requested
      or else Ctx.In_State.Pressed (Quit_Key));

   procedure Close_Window (Ctx : in out Context) is
   begin
      if Ctx.Open then
         Renderer.Shutdown;
         Platform.Close;
         Ctx.Open := False;
      end if;
   end Close_Window;

   function Screen_Width (Ctx : Context) return Positive is (Ctx.Width);
   function Screen_Height (Ctx : Context) return Positive is (Ctx.Height);

   -------------
   -- Drawing --
   -------------

   procedure Begin_Drawing (Ctx : in out Context) is
   begin
      Batch.Reset (Ctx.B);
      Ctx.Cam_Active := False;
   end Begin_Drawing;

   procedure Clear_Background (Ctx : in out Context; C : Color) is
      pragma Unreferenced (Ctx);
   begin
      Renderer.Clear (C);
   end Clear_Background;

   procedure Flush (Ctx : in out Context) is
   begin
      if Ctx.B.Call_Count > 0 then
         Renderer.Draw (Ctx.B);
      end if;
      Batch.Reset (Ctx.B);
   end Flush;

   procedure End_Drawing (Ctx : in out Context) is
      E   : Input.Event;
      Got : Boolean;
      Now : Duration;
   begin
      Flush (Ctx);
      Platform.Swap;
      Input.Begin_Frame (Ctx.In_State);
      Bedrock.Input.Clear (Ctx.Applied);
      for I in 1 .. Ctx.Pending.Count loop
         Input.Apply (Ctx.In_State, Ctx.Pending.Events (I));
         Bedrock.Input.Push (Ctx.Applied, Ctx.Pending.Events (I));
         if Ctx.Pending.Events (I).Kind = Bedrock.Input.Window_Resized
           and then Ctx.Pending.Events (I).Size.Width > 0
           and then Ctx.Pending.Events (I).Size.Height > 0
         then
            Ctx.Width := Positive (Ctx.Pending.Events (I).Size.Width);
            Ctx.Height := Positive (Ctx.Pending.Events (I).Size.Height);
            Renderer.Resize (Ctx.Width, Ctx.Height);
         end if;
      end loop;
      Bedrock.Input.Clear (Ctx.Pending);
      loop
         Platform.Poll (E, Got);
         exit when not Got;
         if Ctx.From_Platform then
            Input.Apply (Ctx.In_State, E);
            Bedrock.Input.Push (Ctx.Applied, E);
            if E.Kind = Bedrock.Input.Window_Resized
              and then E.Size.Width > 0 and then E.Size.Height > 0
            then
               Ctx.Width := Positive (E.Size.Width);
               Ctx.Height := Positive (E.Size.Height);
               Renderer.Resize (Ctx.Width, Ctx.Height);
            end if;
         elsif E.Kind = Bedrock.Input.Quit then
            Ctx.In_State.Quit_Requested := True;   --  the window's X always works
         end if;
      end loop;
      Ctx.Frames := Ctx.Frames + 1;
      Now := Platform.Now;
      Ctx.Frame_Time := Scalar (Now - Ctx.Last_Tick);
      Ctx.Last_Tick := Now;
      Ctx.FPS_Count := Ctx.FPS_Count + 1;
      if Now - Ctx.FPS_Since >= 1.0 then
         Ctx.FPS_Value := Ctx.FPS_Count;
         Ctx.FPS_Count := 0;
         Ctx.FPS_Since := Now;
      end if;
   end End_Drawing;

   procedure Begin_Mode_2D (Ctx : in out Context; Cam : Camera2D) is
   begin
      Ctx.Cam := Cam;
      Ctx.Cam_Active := True;
   end Begin_Mode_2D;

   procedure End_Mode_2D (Ctx : in out Context) is
   begin
      Ctx.Cam_Active := False;
   end End_Mode_2D;

   ----------
   -- Time --
   ----------

   function Get_Frame_Time (Ctx : Context) return Scalar is (Ctx.Frame_Time);
   function Get_Time (Ctx : Context) return Scalar is
      pragma Unreferenced (Ctx);
   begin
      return Scalar (Platform.Now);
   end Get_Time;
   function Get_FPS (Ctx : Context) return Natural is (Ctx.FPS_Value);

   -----------
   -- Input --
   -----------

   function Is_Key_Down (Ctx : Context; K : Key) return Boolean is (Ctx.In_State.Down (K));
   function Is_Key_Pressed (Ctx : Context; K : Key) return Boolean is
     (Ctx.In_State.Pressed (K));
   function Is_Key_Released (Ctx : Context; K : Key) return Boolean is
     (Ctx.In_State.Released (K));
   function Is_Mouse_Button_Down (Ctx : Context; B : Mouse_Button) return Boolean is
     (Ctx.In_State.Button_Down (B));
   function Is_Mouse_Button_Pressed (Ctx : Context; B : Mouse_Button) return Boolean is
     (Ctx.In_State.Button_Pressed (B));
   function Get_Mouse_Position (Ctx : Context) return Vector2 is
     ((Scalar (Ctx.In_State.Mouse_X), Scalar (Ctx.In_State.Mouse_Y)));
   function Get_Mouse_World (Ctx : Context) return Vector2 is
     (if Ctx.Cam_Active then Screen_To_World (Ctx.Cam, Get_Mouse_Position (Ctx))
      else Get_Mouse_Position (Ctx));
   function Input_State (Ctx : Context) return Input.State is (Ctx.In_State);
   function Frame_Events (Ctx : Context) return Input.Event_Queue is (Ctx.Applied);
   function Frame_Number (Ctx : Context) return Natural is (Ctx.Frames);

   procedure Inject (Ctx : in out Context; E : Input.Event) is
   begin
      Bedrock.Input.Push (Ctx.Pending, E);
   end Inject;

   procedure Set_Input_Source (Ctx : in out Context; Platform_Events : Boolean) is
   begin
      Ctx.From_Platform := Platform_Events;
   end Set_Input_Source;

   function Get_Screen_Pixel (Ctx : Context; X, Y : Natural) return Color is
      pragma Unreferenced (Ctx);
   begin
      return Renderer.Read_Pixel (X, Y);
   end Get_Screen_Pixel;

   function Screenshot (Ctx : Context) return Bitmap is
      Img : Bitmap := Bedrock.Buffers.Make (Ctx.Width, Ctx.Height);
   begin
      Renderer.Read_Frame (Img);
      return Img;
   end Screenshot;

   ------------
   -- Submit --
   ------------

   procedure Submit
     (Ctx : in out Context; Tex : Texture_Id; P, UV : Batch.Quad_Corners; C : Color)
   is
      Ok : Boolean;
      Q  : Batch.Quad_Corners := P;
   begin
      if Ctx.Cam_Active then
         for I in Q'Range loop
            Q (I) := World_To_Screen (Ctx.Cam, Q (I));
         end loop;
      end if;
      Batch.Push_Quad (Ctx.B, Tex, Q, UV, C, Ok);
      if not Ok then
         Flush (Ctx);
         Batch.Push_Quad (Ctx.B, Tex, Q, UV, C, Ok);
         --  Still False only while Push_Quad is the placeholder.
      end if;
   end Submit;

   ---------------------------------------------------------------------
   --  Flat API
   ---------------------------------------------------------------------

   procedure Init_Window (Width, Height : Positive; Title : String) is
   begin
      Init_Window (The_Default, Width, Height, Title);
   end Init_Window;
   function Window_Is_Open return Boolean is (Window_Is_Open (The_Default));
   function Window_Should_Close return Boolean is (Window_Should_Close (The_Default));
   procedure Close_Window is
   begin
      Close_Window (The_Default);
   end Close_Window;
   function Screen_Width return Positive is (Screen_Width (The_Default));
   function Screen_Height return Positive is (Screen_Height (The_Default));
   procedure Begin_Drawing is
   begin
      Begin_Drawing (The_Default);
   end Begin_Drawing;
   procedure Clear_Background (C : Color) is
   begin
      Clear_Background (The_Default, C);
   end Clear_Background;
   procedure End_Drawing is
   begin
      End_Drawing (The_Default);
   end End_Drawing;
   procedure Begin_Mode_2D (Cam : Camera2D) is
   begin
      Begin_Mode_2D (The_Default, Cam);
   end Begin_Mode_2D;
   procedure End_Mode_2D is
   begin
      End_Mode_2D (The_Default);
   end End_Mode_2D;
   function Get_Frame_Time return Scalar is (Get_Frame_Time (The_Default));
   function Get_Time return Scalar is (Get_Time (The_Default));
   function Get_FPS return Natural is (Get_FPS (The_Default));
   function Is_Key_Down (K : Key) return Boolean is (Is_Key_Down (The_Default, K));
   function Is_Key_Pressed (K : Key) return Boolean is (Is_Key_Pressed (The_Default, K));
   function Is_Key_Released (K : Key) return Boolean is (Is_Key_Released (The_Default, K));
   function Is_Mouse_Button_Down (B : Mouse_Button) return Boolean is
     (Is_Mouse_Button_Down (The_Default, B));
   function Is_Mouse_Button_Pressed (B : Mouse_Button) return Boolean is
     (Is_Mouse_Button_Pressed (The_Default, B));
   function Get_Mouse_Position return Vector2 is (Get_Mouse_Position (The_Default));
   function Get_Mouse_World return Vector2 is (Get_Mouse_World (The_Default));
   function Get_Screen_Pixel (X, Y : Natural) return Color is
     (Get_Screen_Pixel (The_Default, X, Y));
   function Screenshot return Bitmap is (Screenshot (The_Default));
   procedure Inject (E : Input.Event) is
   begin
      Inject (The_Default, E);
   end Inject;

end Yarlib.Core;
