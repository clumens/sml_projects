(* Handle creation and maintainance of the navigation box appearing just
 * over the main content box on each page.
 *
 * $Id: nav.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure Nav :> NAV =
struct
   (* Convert a path string into a list of parts, each one directory level
    * higher than the next.
    *)
   fun dir_parts dir =
   let
      val f = OS.Path.file dir
      val d = OS.Path.dir dir
   in
      if f <> "" then dir::dir_parts d
      else
         case d of
            "/" => ["/"]
          | ""  => []
          | _   => dir_parts d
   end

   (* Convert a directory path into a string of links for navigation. *)
   fun mk_navbar path =
   let
      (* Make a link to the path component. *)
      fun link url s =
         "<a href=\"" ^ Config.page_url ^ "index.sml?dir=" ^ url ^ "\">" ^
         (if s = "" then "Main" else s) ^ "</a>"

      (* If we're passed an empty path, make sure we at least have a link
       * to Main.
       *)
      val path' = case path of
                     SOME "" => "/"
                   | SOME p  => p
                   | NONE    => "/"
   in
      (* Take the path list and make a link for each one, give the list
       * elements a separator, and finally make one big string out of it.
       *)
      String.concat (Cl.Lst.interleave (map (fn p => link p (OS.Path.file p))
                                            (rev (dir_parts path')))
                                       " :: ")
   end
end
