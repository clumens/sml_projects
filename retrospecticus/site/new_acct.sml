(* Create a new account in the system.  We allow anyone to do this, but
 * having an account currently doesn't let you do very much.
 *
 * $Id: new_acct.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
let
   open Common

   val param_env = Param.mk_param_env Apache.apache_env
   val cookie_env = Cookie.mk_cookie_env Apache.apache_env

   (* Create the "make a new account" form. *)
   fun mk_new_acct_form () =
   let
      fun r_td s =
         "\t\t<td align=\"right\">" ^ s ^ "</td>\n"

      fun l_td s =
         "\t\t<td align=\"left\">" ^ s ^ "</td>\n"

      fun tr s =
         "\t<tr>\n" ^ s ^ "\t</tr>\n"

      val form_body =
          tr (r_td "Login name:" ^
              l_td "<input type=\"text\" name=\"loginName\" size=\"20\" />") ^
          tr (r_td "Password:" ^
              l_td "<input type=\"password\" name=\"pass\" size=\"20\" />") ^
          tr (r_td "Confirm password:" ^
              l_td "<input type=\"password\" name=\"cp\" size=\"20\" />") ^
          tr (r_td "Real name:" ^
              l_td "<input type=\"text\" name=\"realName\" size=\"40\" />") ^
          tr (r_td "Email address:" ^
              l_td "<input type=\"text\" name=\"email\" size=\"40\" />") ^
          tr (r_td "<input type=\"submit\" />" ^
              l_td "<input type=\"reset\" />")
   in
      form "post"
           (Config.page_url ^ "new_acct.sml")
           ("<input type=\"hidden\" name=\"dir\" value=\"" ^ dir ^ "\" />" ^
            Msg.new_acct_insn ^
            "\n\t<table>\n" ^ form_body ^ "</table>")
   end

   (* If the user has already filled out the form, we need to do some
    * processing on it.  Validate all the input, make sure we can create
    * the new account, and then do so.  Display the proper error messages
    * if something goes wrong.
    *)
   fun process_form () =
   let
      open Option User

      val frm = { loginName=getOpt (Env.find param_env "loginName", ""),
                  password=getOpt (Env.find param_env "pass", ""),
                  confirmPassword=getOpt (Env.find param_env "cp", ""),
                  realName=getOpt (Env.find param_env "realName", ""),
                  email=getOpt (Env.find param_env "email", "") }
   in
      if (validInput frm) andalso not (User.userExists Browser.conn
                                                       (#loginName frm)) then
         ( User.createUser Browser.conn frm ; Msg.acct_created )
      else
         Msg.bad_new_acct
   end
in
   Apache.set_page(
      (header "create a new account" Config.style) ^
      (emit_div "titlebox" "Retrospecticus @ bangmoney.org") ^
      linkbox cookie_env param_env ^

      (emit_div "navbox" (Nav.mk_navbar (Env.find param_env "dir")) ^
          (case Env.find param_env "loginName" of
              SOME login => process_form()
            | _          => mk_new_acct_form()
          )) ^

      copyright() ^
      footer()
   )
end
