(* This structure provides a way for the FFI generated code to open the
 * MySQL shared library and manipulate symbols from that library.  It is
 * not used outside the automatically generated code.
 *
 * $Id: libmysql-h.sml,v 1.1 2004/01/04 22:15:43 chris Exp $
 *)
structure LibmysqlH = struct
   local
      val lh = DynLinkage.open_lib { name = "/usr/lib/libmysqlclient.so",
                                     global = true, lazy = true }
   in
      fun libh s =
         let
            val sh = DynLinkage.lib_symbol (lh, s)
         in
            fn () => DynLinkage.addr sh
         end
   end
end
