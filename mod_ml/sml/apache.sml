(* This structure interfaces between pages on the filesystem and the
 * networking layer.  We receive a string from the network and use that to
 * figure out what page to translate.  Those results are then crunched
 * back down into one large string for shipping off to the web server.
 *
 * Pages we execute must build up a list of headers and a page body using
 * set_page and add_header.  Error conditions are represented by an empty
 * body, which the C side of mod_ml will need to convert into the
 * appropriate error code.
 *
 * $Id: apache.sml,v 1.1.1.1 2004/01/04 17:53:19 chris Exp $
 *)
structure Apache :> APACHE =
struct
   (* We need a way for the page to communicate back the evaluated
    * results.  I can't make anything else work, so we'll have to go the
    * imperative route and use a reference.
    *)
   val page = ref ""

   (* The headers to return to the client are kept as a list of
    * (key, value) pairs.  Again, we have to refer to them by reference.
    *)
   val headers: (string * string) list ref = ref []

   (* A table for the environment Apache hands to us.  Pages will want to
    * refer to this for any information they want to know about the
    * request.
    *)
   val apache_env = Env.mk_env()

   (* A function that pages may use to store away their generated text. *)
   fun set_page str =
      ignore (page := str)

   (* A function that pages may use to add a response header. *)
   fun add_header (key, value) =
      ignore (headers := (key, value)::(!headers))

   (* Generate a complete message containing HTML and headers for the
    * web server to send to its clients.  We are passed the entire
    * request's environment, which we first convert into a lookup table.
    * Then extract the file name from that table and translate it in the
    * environment.  Finally, crunch down the headers and page body into
    * one string to return to the network layer.
    *
    * ErrorMsg.Error catches nonexistant or invalid files.
    *)
   fun translate str =
   let
      (* Convert the (key, value) list into a flattened string for sending. *)
      fun mk_header_str str [] =
             str
        | mk_header_str str ((k, v)::lst) =
             str ^ k ^ " " ^ v ^ "\n"

      val _ = Env.init_env apache_env str
      val file = Env.lookup apache_env "SCRIPT_FILENAME"
   in
      ( page := "" ; headers := [] ;      (* clear out previous *)
        use file ;                        (* translate page *)
        Env.clear apache_env ;            (* clear out environment for next *)

        (mk_header_str "" (!headers)) ^ "end\n" ^ !page
      )
   end
   handle Env.NotFound => ""
        | ErrorMsg.Error => ""
end
