(* Display an image by itself on a page.
 *
 * $Id: display.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
let
   open Common

   val param_env = Param.mk_param_env Apache.apache_env
   val cookie_env = Cookie.mk_cookie_env Apache.apache_env

   val dir = Env.find param_env "dir"

   val content = case Env.find param_env "img" of
                    SOME link => "<img src=\"" ^
                                 Dir.fulls (Dir.col_to_url (Option.valOf dir)) ^
                                 "/" ^ link ^ "\" />"
                  | NONE => "<p>You need to pass me an img variable.</p>"
in
   Apache.set_page(
      (header "display picture" Config.style) ^
      (emit_div "titlebox" "Retrospecticus @ bangmoney.org") ^
      linkbox cookie_env param_env ^
      (emit_div "navbox" (Nav.mk_navbar dir)) ^
      (emit_div "collectionbox" content) ^
      copyright() ^
      footer()
   )
end
