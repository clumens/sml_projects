(* Directory manipulation functions.  Convert directory paths from one form
 * to another, check the existance of a directory, and locate a directory
 * in a tree.
 *
 * $Id: dir.sml,v 1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure Dir :> DIR =
struct
   (* Make sure the directory path ends with a / *)
   fun add_slash d =
      if String.isSuffix "/" d then d
      else d ^ "/"

   (* For now, our sanity check is pretty stupid.  If the path contains
    * ".." then we assume it's bad and we'll revert back to the top-level.
    *)
   fun clean dir =
      if String.isSubstring ".." dir then "/"
      else dir

   (* Given a collection path, convert that to a filesystem path. *)
   fun col_to_filesys col =
      Config.pict_dir ^ (add_slash col)

   (* Given a collection path, convert that to a URL. *)
   fun col_to_url col =
      Config.pict_base_url ^ (add_slash col)

   (* See if a directory exists by attempting to open it.  If we get an
    * exception, then it doesn't exist.
    *)
   fun dir_exists dir =
      ( OS.FileSys.closeDir (OS.FileSys.openDir dir) ; true )
   handle SysErr => false

   (* Convert a filesystem path into a collection path by removing the
    * root directory from the beginning of the path.
    *)
   fun filesys_to_col dir =
   let
      open String Config

      (* Drop common elements from two lists. *)
      fun dropeq (str_a::lst_a) (str_b::lst_b) =
             if str_a = str_b then dropeq lst_a lst_b
             else str_a::dropeq lst_a lst_b
        | dropeq lst_a [] =
             lst_a
   in
      if isPrefix dir pict_dir then
         let
            val is_slash = (fn ch => ch = #"/")
         in
            concat (Cl.Lst.interleave (dropeq (tokens is_slash dir)
                                              (tokens is_slash pict_dir))
                                      "/")
         end
      else
         ""
   end

   (* Give the subdirectory where full sized images are stored. *)
   fun fulls dir =
      add_slash dir ^ "f"

   (* If the last character in a string is a slash, remove it. *)
   fun rm_slash dir =
   let
      open Substring
   in
      if String.isSuffix "/" dir then
         string (trimr 1 (full dir))
      else
         dir
   end

   (* Give the subdirectory where thumbnails are stored. *)
   fun thumbs dir =
      add_slash dir ^ "t"
end
