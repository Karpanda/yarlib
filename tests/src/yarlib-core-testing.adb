
package body Yarlib.Core.Testing is

   function Batch_Call_Count (Ctx : Context) return Natural is
   begin
      return Natural (Ctx.B.Call_Count);
   end Batch_Call_Count;

   function Batch_Vertex_Count (Ctx : Context) return Natural is
   begin
      return Natural (Ctx.B.Vertex_Count);
   end Batch_Vertex_Count;

end Yarlib.Core.Testing;
