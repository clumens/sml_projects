(* Manage environment tables throughout the browser.  All our tables are
 * string -> string mappings.  Specific environments will have functions
 * to create their initial environments, so those should be called first.
 * For the most part, this structure is for internal use.
 *
 * $Id: env.sig,v 1.1 2004/01/04 17:53:19 chris Exp $
 *)
signature ENV =
sig
   exception NotFound

   type env = (string, string) HashTable.hash_table

   (* Create a blank environment. *)
   val mk_env: unit -> env

   (* Initialize an environment from a string of "key\nvalue". *)
   val init_env: env -> string -> unit

   (* Wrapper functions to hide the internal representation. *)
   val clear: env -> unit
   val insert: env -> string * string -> unit
   val lookup: env -> string -> string
   val find: env -> string -> string option
   val remove: env -> string -> string
   val listItems: env -> string list
   val listItemsi: env -> (string * string) list
end
