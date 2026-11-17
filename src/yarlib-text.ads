
--  Text: bitmap font rendering using the shared font atlas.

with Yarlib.Core; use Yarlib.Core;

package Yarlib.Text is

   function Measure_Text
     (Text : String; Size : Positive) return Integer;

   procedure Draw_Text
     (Ctx : in out Context;
      Text : String;
      X, Y : Integer;
      Size : Positive;
      Tint : Color := White);

   procedure Draw_Text
     (Text : String;
      X, Y : Integer;
      Size : Positive;
      Tint : Color := White);

end Yarlib.Text;