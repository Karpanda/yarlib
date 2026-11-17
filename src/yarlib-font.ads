with Bedrock; use Bedrock;

package Yarlib.Font is

   Glyph_Width  : constant Positive := 8;
   Glyph_Height : constant Positive := 8;

   Atlas_Width  : constant Positive := 128;
   Atlas_Height : constant Positive := 64;

   function Build_Atlas return Bitmap;

   function Source (C : Character) return Rectangle;

end Yarlib.Font;