(* Manage an environment of GET parameters and form values.  Just like the
 * cookies, this is managed with a table.  You need to create the
 * environment first with mk_param_env.
 *
 * $Id: param.sml,v 1.1.1.1 2004/01/04 17:53:19 chris Exp $
 *)
structure Param :> PARAM =
struct
   (* Extract the string of parameters.  If it's a POST method, we need to
    * read a big chunk of stuff from the request.  If it's a GET, all the
    * parameters are encoded in the URL.  When in doubt, assume GET.
    *)
   fun query_string apache_env =
   let
      fun intOf NONE = NONE
        | intOf (SOME s) = Int.fromString s
   in
      case Env.find apache_env "REQUEST_METHOD" of
         SOME ("POST") =>
            Option.getOpt (Env.find apache_env "Post-Content", "")
       | _ =>
            Option.getOpt (Env.find apache_env "QUERY_STRING", "")
   end

   (* If this is a multipart request, we need to know what the boundaries
    * are so we know how to split the parameter string up into its parts.
    *)
   fun multipart_boundary () =
   let
      open Substring

      val content_type = all (Option.getOpt (Env.find Apache.apache_env
                                             "CONTENT_TYPE", ""))

      fun getboundary line =
      let
         val (_, bound) = position "boundary=" line
      in
         if isEmpty bound then NONE
         else SOME(string (triml 1 (dropl (fn ch => ch <> #"=") bound)))
      end
      handle Option => NONE
   in
      if isPrefix "multipart/form-data;" content_type then
         getboundary content_type
      else
         NONE
   end
   handle Option => NONE

   (* Given a single parameter's key or value, decode whatever might
    * have been done to it to put it into a URL, and return the regular
    * string version.
    *)
   fun decode param =
   let
      open Substring

      (* Convert a hexadecimal character into a digit. *)
      fun dehex ch =
         if Char.isDigit ch then
            Char.ord(ch) - Char.ord(#"0")
         else
            if #"A" <= ch andalso ch <= #"F" then
               (Char.ord(ch) - Char.ord(#"A")) + 10
            else
               if #"a" <= ch andalso ch <= #"f" then
                  (Char.ord(ch) - Char.ord(#"a")) + 10
               else
                  0

      (* Turn "%xx" into a special character. *)
      fun decode_num i =
         Char.chr (16 * dehex(sub(param, i+1)) + dehex(sub(param, i+2)))

      (* Scan across the parameter string, converting "+" to spaces,
       * "%xx" into a special character, and leaving regular characters
       * unmolested.  Returns a list of characters which can be turned
       * back into a string.
       *)
      fun conv ndx =
         if ndx >= size param then []
         else
            case sub(param, ndx) of
               #"+" => #" "::conv(ndx+1)
             | #"%" => decode_num(ndx)::conv(ndx+3)
             | ch   => ch::conv(ndx+1)
   in
      String.implode(conv 0)
   end

   (* Construct an environment for all the URL parameters and return that
    * environment.
    *)
   fun mk_param_env apache_env =
   let
      open Substring
      val param_env = Env.mk_env()

      (* If we're not multipart, just break the query string up on the
       * ampersands into a list of key=value.  Otherwise, return empty.
       *)
      fun split_query_str () =
         case multipart_boundary() of
            NONE => tokens (fn ch => ch = #"&") (all (query_string apache_env))
          | _    => []

      (* Insert a new mapping into the parameter environment. *)
      fun add_to_env env [key, value] =
         Env.insert env (decode key, decode value)
   in
      (* Convert the list of key=value into a list of [key, value], insert
       * it, and return the finished table.
       *)
      ignore (map (add_to_env param_env)
                  (map (fields (fn ch => ch = #"=")) (split_query_str ()))) ;
      param_env
   end
end
