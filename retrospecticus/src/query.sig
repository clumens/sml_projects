(* Utility functions to generate SQL query statements.
 *
 * $Id: query.sig,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
signature QUERY =
sig
   (* One form of the datatype for each query we can possibly generate. *)
   datatype query =
      insertUser of string * string * string * string * bool * bool * bool
    | insertOwner of string * string

   val toString: query -> string
end
