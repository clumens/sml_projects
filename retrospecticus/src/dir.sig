(* Directory manipulation functions.  Convert directory paths from one form
 * to another, check the existance of a directory, and locate a directory
 * in a tree.
 *
 * $Id: dir.sig,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
signature DIR =
sig
   val add_slash: string -> string
   val clean: string -> string
   val col_to_filesys: string -> string
   val col_to_url: string -> string
   val dir_exists: string -> bool
   val filesys_to_col: string -> string
   val fulls: string -> string
   val rm_slash: string -> string
   val thumbs: string -> string
end
