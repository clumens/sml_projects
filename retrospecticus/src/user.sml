(* Manage system users.  Note that in this layer, we do not handle any
 * exceptions that might be thrown by the SQL functions we're calling.
 * Since we don't know enough about what's going on in the system as a
 * whole, we simply leave exception handling to the topmost level.
 *
 * $Id: user.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure User :> USER =
struct
   type user = {loginName: string, password: string, confirmPassword: string,
                realName: string, email: string}

   (* See if the user is logged in by checking for a valid "login" cookie
    * from the client's browser, if they are in the login environment, and
    * if their current IP matches that of the values in the environment.
    *)
   fun logged_in cookie_env param_env =
   let
      val host = case Env.find param_env "REMOTE_ADDR" of
                    SOME addr => addr
                  | _         => ""
   in
      case Env.find cookie_env "login" of
         SOME name => 
            ( case Env.find Browser.login_env name of
                 SOME addr => if addr = host then SOME(name) else NONE
               | _         => NONE
            )
       | _      => NONE
   end

   (* Validate all the values provided on the user creation form. *)
   fun validInput {loginName=user, password=p, confirmPassword=cp,
                   realName=name, email=email} =
      if user <> "" andalso p <> "" andalso p=cp andalso name <> "" andalso
         email <> "" then true
      else false

   (* Does a user exist in the system with the given name? *)
   fun userExists conn user =
      case MySQL.count conn "Site_User" ("login_name=\"" ^ user ^ "\"") of
         SOME i => if i > 0 then true else false
       | NONE   => false

   (* Attempt to log a user into the system, returning success or not. *)
   fun authenticate conn user pass =
   let
      val q = "login_name=\"" ^ MySQL.clean user ^
              "\" AND password=SHA(\"" ^ MySQL.clean pass ^ "\")"
   in
      case MySQL.count conn "Site_User" q of
         SOME i => if i > 0 then true else false
       | NONE   => false
   end

   (* Given the new account information, run the SQL statements necessary
    * to add the user into the system.  Note that all the proper checks
    * must be carried out first since we're not doing any validation here.
    *)
   fun createUser conn {loginName=user, password=pass, realName=name,
                        email=email, confirmPassword=cp} =
   let
      val user_q = Query.insertUser(user, pass, name, email, true, false, false)
   in
      MySQL.app conn (fn lst => ()) (Query.toString user_q)
   end
   handle MySQL.SqlExn str => print ("*** " ^ str ^ "\n")
end
