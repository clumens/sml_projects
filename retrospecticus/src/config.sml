(* mod_ml configuration for the ML side of things.  For the most part,
 * this should be easy for anyone to modify.
 *
 * $Id: config.sml,v 1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure Config =
struct
   (* Set this to the port you want the SML/NJ process to listen on. *)
   val port = 4747

   (* A comma separated list of SML files which will be "use"d before your
    * pages are executed, in the order they should be loaded.  Think of
    * these as individual, standalone support files for your pages.
    *
    * At the very least, you need common.sml.
    *)
   val preload = ["/home/chris/public_html/common.sml"]

   (* A comma separated list of CM source files which will be autoloaded.
    * Think of these as libraries which should be loaded only when needed.
    *
    * At the very least, you need sources.cm from the photo browser.
    *)
   val autoload = ["/home/chris/ml_projects/photo/src/sources.cm"]

   (* Where you've installed the photo browser files. *)
   val page_dir = "/home/chris/public_html/"

   (* And the root of where your pictures are stored. *)
   val pict_dir = page_dir ^ "pics"

   (* The base of the URL for the photo browser. *)
   val page_url = "/~chris/"

   (* The base of the URL for where your pictures are stored. *)
   val pict_base_url = page_url ^ "pics"

   (* The base of the URL for the browser's style sheet. *)
   val style = page_url ^ "style.css"

   (* Which icon set to use. *)
   val icon_dir = page_url ^ "icons/space/"
end
