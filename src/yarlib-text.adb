
with Bedrock; use Bedrock;
with Yarlib.Font;
with Yarlib.Textures;

package body Yarlib.Text is

   Font_Texture : Texture;
   Font_Loaded  : Boolean := False;

   procedure Ensure_Font;

   procedure Ensure_Font is
   begin
      if not Font_Loaded then
         Font_Texture :=
           Textures.Load_Texture (Font.Build_Atlas);
         Font_Loaded := True;
      end if;
   end Ensure_Font;

   function Measure_Text
     (Text : String; Size : Positive) return Integer
   is
   begin
      return Text'Length * Size;
   end Measure_Text;

   procedure Draw_Text
     (Ctx : in out Context;
      Text : String;
      X, Y : Integer;
      Size : Positive;
      Tint : Color := White)
   is
      Scale : constant Scalar :=
        Scalar (Size) / Scalar (Font.Glyph_Height);

      Glyph_Size : constant Scalar :=
        Scalar (Font.Glyph_Width) * Scale;

      Cursor_X : Scalar := Scalar (X);
      Source_Rect : Rectangle;
      Dest_Rect   : Rectangle;
   begin
      if Text'Length = 0 then
         return;
      end if;

      Ensure_Font;

      for C of Text loop
         if C in ' ' .. '~' then
            Source_Rect := Font.Source (C);
         else
            Source_Rect := Font.Source ('?');
         end if;

         Dest_Rect :=
           (X      => Cursor_X,
            Y      => Scalar (Y),
            Width  => Glyph_Size,
            Height => Scalar (Size));

         Textures.Draw_Texture_Pro
           (Ctx,
            Font_Texture,
            Source_Rect,
            Dest_Rect,
            (0.0, 0.0),
            0.0,
            Tint);

         Cursor_X := Cursor_X + Glyph_Size;
      end loop;
   end Draw_Text;

   procedure Draw_Text
     (Text : String;
      X, Y : Integer;
      Size : Positive;
      Tint : Color := White)
   is
   begin
      Draw_Text
        (Core.Default.all, Text, X, Y, Size, Tint);
   end Draw_Text;

end Yarlib.Text;
