(* Handle checking that the current user has permission to do whatever
 * they are trying to do.
 *
 * $Id: permission.sig,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
signature PERMISSION =
sig
   val user_may_create: string -> string -> bool
   val new_collection: string -> string -> unit
end
