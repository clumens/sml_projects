(* Manage and manipulate collections.  A collection is the analogue of a
 * directory on a filesystem - it can hold photos as well as other
 * collections, allowing arbitrarily complex structures.
 *
 * $Id: collection.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure Collection :> COLLECTION =
struct
   exception CollectionErr

   type collection = {owner: string, name: string, dir_name: string,
                      parent: string}

   (* Get the contents of a directory.  If get_dirs is true, round up all
    * the subdirectories.  Otherwise, get files.
    *)
   fun contents d get_dirs =
   let
      open OS.FileSys OS.Path
   
      (* Return a list of everything in a directory. *)
      fun rd dir =
         case readDir dir of
            SOME d => d::rd dir
          | _      => ( closeDir dir ; [] )
      handle exn => raise CollectionErr
   in
      ( if get_dirs then
           List.filter (fn f => isDir (joinDirFile {dir=d, file=f}))
        else
           List.filter (fn f => not (isDir (joinDirFile {dir=d, file=f})))
      ) (rd (openDir d))
   end
   handle SysErr => []

   (* Make a list of links for the contents of this collection. *)
   fun to_list path =
   let
      (* We can't touch "path" until we sanitize it, because it comes from
       * the user's browser.  real_path' is the filesystem equivalent.
       *)
      val path' = Dir.clean (Dir.add_slash path)
      val real_path' = Dir.col_to_filesys path'

      val dirs = contents real_path' true
      val files = contents (Dir.thumbs real_path') false

      (* Make a link to each subdirectory of the current collection, 
       * except for the special subdirectories that hold the pictures.
       *)
      fun dir_part dirs =
      let
         (* Create the string for a link to a direction. *)
         fun d_link p s =
         let
            open Substring

            (* See if there's a "name" file in the directory and use its
             * contents for the visible chunk of the link.  If not, just
             * use the directory's name.
             *)
            fun get_name dir =
            let
               val file = TextIO.openIn (dir ^ "name")
            in
               (TextIO.inputLine file) before TextIO.closeIn file
            end
            handle _ => OS.Path.file (Dir.rm_slash dir)

            (* Figure out which icon gets displayed. *)
            fun get_img_link p =
               if p = "/" then Config.icon_dir ^ "user.gif"
               else Config.icon_dir ^ "collection.gif"
         in
            "<a href=\"" ^ Config.page_url ^ "index.sml?dir=" ^ p ^ "\">" ^
            "<img src=\"" ^ get_img_link path' ^ "\" /><br />" ^
            get_name (Dir.col_to_filesys p) ^
            "</a>"
         end
      in
         if null dirs then []
         else map (fn d => d_link (path' ^ d) d)
                  (List.filter (fn d => d <> "t" andalso d <> "f") dirs)
      end

      (* Make a link to each picture in the current collection. *)
      fun file_part files =
      let
         fun f_link p s =
            "<a href=\"" ^ Config.page_url ^ "display.sml?" ^
            "dir=" ^ p ^ "&" ^
            "img=" ^ s ^ "\">" ^
            "<img src=\"" ^ Dir.thumbs (Dir.col_to_url p) ^ "/" ^ s ^ "\" />" ^
            "<br />" ^ s ^
            "</a>"
      in
         if null files then []
         else map (fn f => f_link path' f) files
      end
   in
      dir_part dirs @ file_part files
   end

   (* Validate all the values provided on the new collection form. *)
   fun valid_input {owner=owner, name=name, dir_name=dir_name, parent=parent} =
      if owner <> "" andalso name <> "" andalso dir_name <> "" andalso
         parent <> "" then true
      else false

   (* Create a new collection on disk.  Make sure to check that the user
    * can create the collection before calling this.
    *)
   fun create (col: collection) =
   let
      val fs_dir = (#parent col) ^ "/" ^ (#dir_name col)
      val col_dir = Dir.col_to_filesys fs_dir

      (* Write the collection's name.  We should always have a name file,
       * but the reading code assumes it's possible we do not.
       *)
      fun write_name f name =
      let
         val file = TextIO.openOut f
      in
         (TextIO.output (file, name)) before TextIO.closeOut file
      end
      handle _ => raise CollectionErr
   in
      if Dir.dir_exists col_dir then
         raise CollectionErr
      else
         OS.FileSys.mkDir col_dir ;
         OS.FileSys.mkDir (Dir.thumbs col_dir) ;
         OS.FileSys.mkDir (Dir.fulls col_dir) ;
         write_name ((Dir.add_slash col_dir) ^ "name") (#name col) ;
         Permission.new_collection (Dir.add_slash fs_dir) (#owner col)
   end
   handle _ => raise CollectionErr
end
