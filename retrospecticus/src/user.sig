(* Functions to manage the system's users including account creation,
 * authentication, and validation.  Note that in this layer, we do not
 * handle any exceptions that might be thrown by the SQL functions we're
 * calling.  Since we don't know enough about what's going on in the
 * system as a whole, we simply leave exception handling to the topmost
 * level.
 *
 * $Id: user.sig,v 1.1 2004/01/04 17:53:20 chris Exp $
 *)
signature USER =
sig
   (* This type holds all the values the user fills in on a new account
    * creation form, making it easier to pass that information around.
    *)
   type user = {loginName: string, password: string, confirmPassword: string,
                realName: string, email: string}

   (* Check the cookie environment to see if the remote host is logged in
    * or not.
    *)
   val logged_in: Env.env -> Env.env -> string option

   (* Given an open connection, a username, and a password, attempt to
    * log a user into the system.  Return a boolean value for success.
    *)
   val authenticate: MySQL.conn -> string -> string -> bool
   
   (* Add a user to the system.  Note that all the proper checks must be
    * carried out first.
    *)
   val createUser: MySQL.conn -> user -> unit

   (* Given an open connection and a username, see if that name is in use. *)
   val userExists: MySQL.conn -> string -> bool

   (* Validate all fields of the account creation form. *)
   val validInput: user -> bool
end
