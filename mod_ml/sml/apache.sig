(* Interface between the networking layer and pages on the filesystem that
 * are to be executed.
 *
 * $Id: apache.sig,v 1.1.1.1 2004/01/04 17:53:19 chris Exp $
 *)
signature APACHE =
sig
   (* Tables pages will want to look at. *)
   val apache_env: (string, string) HashTable.hash_table

   (* Functions for the page side of the interface. *)
   val set_page: string -> unit
   val add_header: (string * string) -> unit

   (* Functions for the networking side of the interface. *)
   val translate: string -> string
end
