(* Unfortunately, we need a copyright and terms of use page since we're
 * letting other people use/see/post/comment/upload/etc.  This gets linked
 * to from the bottom of every page.
 *
 * $Id: copyright.sml,v 1.1 2004/01/04 17:53:20 chris Exp $
 *)
let
   open Common

   val param_env = Param.mk_param_env Apache.apache_env
   val cookie_env = Cookie.mk_cookie_env Apache.apache_env

   val cpy = "<h2>Copyright statement</h2>\n"
   val terms = "<h2>Terms of use</h2>"
in
   Apache.set_page(
      (header "copyright and terms of use" Config.style) ^
      (emit_div "titlebox" "Retrospecticus @ bangmoney.org") ^
      linkbox cookie_env param_env ^
      (emit_div "navbox" (Nav.mk_navbar (Env.find param_env "dir"))) ^
      (emit_div "collectionbox" (cpy ^ terms)) ^
      copyright() ^
      footer()
   )
end
