(* $Id: uri.sml,v 1.4 2004/07/26 19:02:43 chris Exp $ *)

(* Copyright (c) 2004, Chris Lumens
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - The names of the contributors may not be used to endorse or promote
 *   products derived from this software without specific prior written
 *   permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)
structure URI :> URI =
struct
   datatype URI = http of {user: string, password: string, host: string,
                           port: int, path: string, query: string, frag: string}
                | unknown of {scheme: string, auth: string, path: string,
                              query: string, frag: string}

   structure DFA = RegExpFn(structure P=AwkSyntax
                            structure E=BackTrackEngine)

   fun parse str =
   let
      fun match str tree =
      let
         fun find n =
            case MatchTree.nth (tree, n) of
               SOME {pos, len} => String.substring (str, pos, len)
             | NONE            => ""

         fun auth str =
            case (String.tokens (fn ch => ch = #":") str) of
               n::[]    => (n, "")
             | n::p::[] => (n, p)
             | _        => ("", "")

         fun remote str =
            case (String.tokens (fn ch => ch = #":") str) of
               h::[]    => (h, 80)
             | h::p::[] => (h, Option.getOpt (Int.fromString p, 80))
             | _        => ("", 80)

         fun parse_http () =
            case (String.tokens (fn ch => ch = #"@") (find 4)) of
               r::[] =>
                  let
                     val (host, port) = remote r
                  in
                     http{user="", password="", host=host, port=port,
                          path=(find 5), query=(find 7), frag=(find 9)}
                  end
             | a::r::[] =>
                  let
                     val (user, password) = auth a
                     val (host, port) = remote r
                  in
                     http{user=user, password=password, host=host, port=port,
                          path=(find 5), query=(find 7), frag=(find 9)}
                  end
             | _ => http{user="", password="", host="", port=80,
                         path=(find 5), query=(find 7), frag=(find 9)}
      in
         case (find 2) of
            "http"   => parse_http ()
          | s        => unknown{scheme=s, auth=(find 4), path=(find 5),
                                query=(find 7), frag=(find 9)}
      end

      (* Regular expression from RFC 2396, appendix B. *)
      val re = DFA.compileString "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
   in
      case StringCvt.scanString (DFA.find re) str of
         NONE      => NONE
       | SOME tree => SOME(match str tree)
   end

   fun toString (http{user, password, host, port, path, query, frag}) =
      "http://" ^
      (if user <> "" andalso password <> "" then user ^ ":" ^ password ^ "@"
       else
          if user <> "" andalso password = "" then user ^ "@" else "") ^
      host ^
      (if port = 80 orelse port = 0 then "" else ":" ^ Int.toString port) ^
      path ^
      (if query = "" then "" else "?" ^ query) ^
      (if frag = "" then "" else "#" ^ frag)

     | toString (unknown{scheme, auth, path, query, frag}) =
      scheme ^ "://" ^ auth ^ path ^
      (if query = "" then "" else "?" ^ query) ^
      (if frag = "" then "" else "#" ^ query)
end