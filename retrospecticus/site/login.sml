(* The login page.  This page shows the login form and interfaces with the
 * database code to authenticate them to the system.
 *
 * $Id: login.sml,v 1.1 2004/01/04 17:53:20 chris Exp $
 *)
let
   open Common

   val param_env = Param.mk_param_env Apache.apache_env
   val cookie_env = Cookie.mk_cookie_env Apache.apache_env

   val dir = Env.find param_env "dir"

   (* The login form needs more specialized forms of the <td> generators
    * which is why we're duplicating that stuff here.  Note that it's
    * still a bit of a mess.
    *)
   fun mk_login_form dir =
   let
      fun r_td s =
         "\t<td align=\"right\">" ^ s ^ "</td>\n"

      fun l_td s =
         "\t<td align=\"left\">" ^ s ^ "</td>\n"

      fun tr s =
         "<tr>\n" ^ s ^ "</tr>\n"

      fun input ty name size =
         "<input type=\"" ^ ty ^ "\" name=\"" ^ name ^ "\" size=\"" ^
         size ^ "\" />"
   in
      form "post" (Config.page_url ^ "login.sml")
                  ("<input type=\"hidden\" name=\"dir\" value=\"" ^ dir ^
                   "\" />" ^
                   "<table>\n" ^
                   tr (r_td "Login name:" ^
                       l_td (input "text" "loginName" "20")) ^
                   tr (r_td "Password:" ^
                       l_td (input "password" "pass" "20")) ^
                   tr (r_td "<input type=\"submit\" />" ^
                       l_td "<input type=\"reset\" />") ^
                   "</table>")
   end

   (* Create the cookie we're going to send back to the client, indicating
    * that they are logged in.
    *)
   fun mk_cookie login =
   let
      open Time

      val expiry = Date.fromTimeUniv (Time.+ (now(), fromSeconds(3600)))
   in
      Cookie.mk_cookie {name="login", value=login, expiry=SOME(expiry),
                        domain=Env.find Apache.apache_env "SERVER_NAME",
                        path=SOME(Config.page_url), secure=true}
   end

   (* See if the provided username and password are valid.  If so, then
    * store a cookie on the remote host and enter them into a table so
    * we know who all is logged in.
    *)
   fun check_db login =
   let
      val host = case Env.find param_env "REMOTE_ADDR" of
                    SOME addr => addr
                  | _         => ""
   in
      case Env.find param_env "pass" of
         SOME pass =>
            if User.authenticate Browser.conn login pass then
               ( Apache.add_header ("Set-Cookie: ", mk_cookie login) ;
                 Env.insert Browser.login_env (login, host) ;
                 Msg.logged_in
               )
            else
               Msg.bad_name_password
       | _         =>
            Msg.bad_name_password
   end
   handle MySQL.SqlExn str => ("<p>MySQL exn: " ^ str ^ "</p>\n")
in
   Apache.set_page(
      (header "user login" Config.style) ^
      (emit_div "titlebox" "Retrospecticus @ bangmoney.org") ^
      linkbox cookie_env param_env ^
      (emit_div "navbox" (Nav.mk_navbar dir)) ^

      (emit_div "collectionbox" 
                (case Env.find param_env "loginName" of
                    SOME login => check_db login
                  | _          => mk_login_form (Option.getOpt (dir, "/"))
                )) ^

      copyright() ^
      footer()
   )
end
