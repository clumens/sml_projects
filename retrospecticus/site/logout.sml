(* Logout the current user.
 *
 * $Id: logout.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
let
   open Common

   val param_env = Param.mk_param_env Apache.apache_env
   val cookie_env = Cookie.mk_cookie_env Apache.apache_env

   (* To log a user out, first delete them from the login_env, then send
    * them an expired cookie.  Returns whether or not we logged them out.
    *)
   fun logout_user () =
   let
      val c = Cookie.delete_cookie {name="login", value="bogus",
                                    expiry=NONE, domain=NONE,
                                    path=SOME(Config.page_url),
                                    secure=false}
   in
      (* Only log them out if their environment includes a cookie. *)
      case Env.find cookie_env "login" of
         SOME n => ( Env.remove Browser.login_env n ;
                     Apache.add_header ("Set-Cookie: ", c) ;
                     true
                   )
       | _ => false
   end

   (* Given the results of logout_user, determine what sort of linkbox
    * needs to go at the top of the page, then fill in the content
    * section.
    *)
   val content =
      (fn b => linkbox cookie_env param_env ^
               (emit_div "navbox" (Nav.mk_navbar (Env.find param_env "dir"))) ^
               (emit_div "collectionbox" (if b then Msg.logged_out
                                          else Msg.not_logged_in)))
in
   Apache.set_page(
      (header "logout" Config.style) ^
      (emit_div "titlebox" "Retrospecticus @ bangmoney.org") ^
      (content) (logout_user()) ^
      copyright() ^
      footer()
   )
end
