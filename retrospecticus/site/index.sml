(* This is the main page from the photo browser.
 *
 * $Id: index.sml,v 1.1 2004/01/04 17:53:20 chris Exp $
 *)
let
   open Common

   (* What's located in this collection? *)
   fun contents dir =
   let
      val lst = Collection.to_list (Option.getOpt (dir, "/"))
   in
      String.concat (map tr (Cl.Lst.split 5 lst))
   end
   handle exn => Msg.invalid_collection

   val param_env = Param.mk_param_env Apache.apache_env
   val cookie_env = Cookie.mk_cookie_env Apache.apache_env

   (* Where are we? *)
   val dir = Env.find param_env "dir"
in
   Apache.set_page(
      (header "browse" Config.style) ^
      (emit_div "titlebox" "Retrospecticus @ bangmoney.org") ^
      linkbox cookie_env param_env ^
      (emit_div "navbox" (Nav.mk_navbar dir)) ^
      (emit_div "collectionbox" ("\n<table>\n" ^
                                 contents dir ^
                                 "</table>\n\n")) ^
      copyright() ^
      footer()
   )
end
