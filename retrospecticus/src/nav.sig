(* Handle creation and maintainance of the navigation box appearing just
 * over the main content box on each page.
 *
 * $Id: nav.sig,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
signature NAV =
sig
   val dir_parts: string -> string list
   val mk_navbar: string option -> string
end
