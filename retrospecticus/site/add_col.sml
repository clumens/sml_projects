(* Make a new collection as a child of the current one.
 *
 * $Id: add_col.sml,v 1.1 2004/01/04 17:53:19 chris Exp $
 *)
let
   open Common

   val param_env = Param.mk_param_env Apache.apache_env
   val cookie_env = Cookie.mk_cookie_env Apache.apache_env

   (* Where are we located? *)
   val dir = Env.find param_env "dir"

   fun mk_new_col_form dir =
   let
      fun r_td s =
         "\t\t<td align=\"right\">" ^ s ^ "</td>\n"

      fun l_td s =
         "\t\t<td align=\"left\">" ^ s ^ "</td>\n"

      fun tr s =
         "\t<tr>\n" ^ s ^ "\t</tr>\n"

      val form_body =
         tr (r_td "Collection name:" ^
             l_td "<input type=\"text\" name=\"colName\" size=\"50\" />") ^
         tr (r_td "Collection directory:" ^
             l_td "<input type=\"text\" name=\"colDir\" size=\"50\" />") ^
         tr (r_td "<input type=\"submit\" />" ^
             l_td "<input type=\"reset\" />")
   in
      form "post"
           (Config.page_url ^ "add_col.sml")
           ("<input type=\"hidden\" name=\"dir\" value=\"" ^ dir ^ "\" />" ^
            Msg.new_col_insn ^
            "\n\t<table>\n" ^ form_body ^ "</table>")
   end

   fun process_form owner parent name =
   let
      open Option Collection

      val c = { owner=owner, name=name,
                dir_name=getOpt (Env.find param_env "colDir", ""),
                parent=parent }
   in
      if valid_input c then
         ( create c ; Msg.collection_created )
      else
         Msg.bad_new_collection
   end
   handle Collection.CollectionErr => Msg.bad_new_collection
in
   Apache.set_page(
      (header "main" Config.style) ^
      (emit_div "titlebox" "Retrospecticus @ bangmoney.org") ^
      linkbox cookie_env param_env ^
      (emit_div "navbox" (Nav.mk_navbar dir)) ^

      (* First, make sure the user is logged in since a guest user can't
       * create a collection.  Then, make sure the logged in user has
       * permission on the current collection to make a new one.  Finally,
       * either make or process the form - depending on the form's state.
       *)
      (emit_div "collectionbox"
          (case User.logged_in cookie_env param_env of
              SOME owner =>
                 let
                    val dir' = Option.getOpt (dir, "/")
                 in
                    if Permission.user_may_create dir' owner then
                       case Env.find param_env "colName" of
                          SOME col_name => process_form owner dir' col_name
                        | _             => mk_new_col_form dir'
                    else
                       Msg.no_new_col_perms
                 end
            | _ => Msg.col_must_be_logged_in
          )) ^

      copyright() ^
      footer()
   )
end
