(* Create, delete, and manage browser cookies.  Like everything else, we
 * manage them by constructing a table from the HTTP Cookie: header.  Call
 * mk_cookie_env before doing anything with cookies to construct this
 * environment table
 *
 * $Id: cookie.sml,v 1.1.1.1 2004/01/04 17:53:19 chris Exp $
 *)
structure Cookie :> COOKIE =
struct
   exception CookieError of string

   type cookie = {name: string, value: string, expiry: Date.date option,
                  domain: string option, path: string option, secure: bool}

   fun concatOpt s NONE     = ""
     | concatOpt s (SOME t) = s ^ t

   (* Build an environment table for all the cookies that the client sent
    * back to us.  This needs to be called on every page that needs to
    * read cookie values.
    *)
   fun mk_cookie_env apache_env =
   let
      open Substring

      val cookie_env  = Env.mk_env()
      val http_cookie = Env.find apache_env "HTTP_COOKIE"

      (* Remove all the whitespace characters from a string. *)
      fun remove_ws str =
         concat (fields (fn ch => Char.isSpace ch) str)

      (* Given a list of key=value, split the parts out of it and then
       * insert those into the cookie dictionary.
       *)
      fun ins (kv::lst) =
             let
                val kv' = fields (fn ch => ch = #"=") (full kv)
                val k = hd kv'
                val v = hd (tl kv')
             in
                ( Env.insert cookie_env (string k, string v) ; ins lst )
             end
        | ins ([]) =
             cookie_env
   in
      case http_cookie of
         (* Given the HTTP_COOKIE variable, break it up on the semicolons
          * into key=value strings, then remove any whitespace in those
          * strings.  Return the constructed environment, or an empty one.
          *)
         SOME str => ins (map remove_ws (tokens (fn ch => ch = #";" )
                                                (all str)))
       | _        => cookie_env
   end

   (* Build a single cookie string that we can send to the clients. *)
   fun mk_cookie (c: cookie) =
   let
      fun datefmt date =
         Date.fmt "%A, %d-%b-%Y %H:%M:%S UTC" date
   in
      if #name c = "" orelse #value c = "" then
         raise CookieError "Cookie needs a name and a value"
      else
         String.concat [#name c, "=", #value c,
                        concatOpt "; expires=" (Option.map datefmt (#expiry c)),
                        concatOpt "; domain=" (#domain c),
                        concatOpt "; path=" (#path c),
                        (if #secure c = true then "; secure"
                         else ""),
                        "\n"]
   end

   (* Make a bunch of cookies. *)
   fun mk_cookies cookies =
      String.concat (map mk_cookie cookies)

   (* We delete a cookie by setting the expiration date to before the
    * current time.
    *)
   fun delete_cookie (c: cookie) =
      String.concat ["Set-cookie: ", #name c, "=deleted; ",
                     "expires=Thursday, 20-Dec-79 12:00:00 GMT",
                     concatOpt "; path=" (#path c), "\n"]
end
