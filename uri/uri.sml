(* $Id *)

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

         fun remote str default_port =
            case (String.tokens (fn ch => ch = #":") str) of
               h::[]    => (h, default_port)
             | h::p::[] => (h, Option.getOpt (Int.fromString (p), default_port))
             | _        => ("", default_port)

         fun parse_http default_port =
            case (String.tokens (fn ch => ch = #"@") (find 4)) of
               r::[] =>
                  let
                     val (host, port) = remote r default_port
                  in
                     http{user="", password="", host=host, port=port,
                          path=(find 5), query=(find 7), frag=(find 9)}
                  end
             | a::r::[] =>
                  let
                     val (user, password) = auth a
                     val (host, port) = remote r default_port
                  in
                     http{user=user, password=password, host=host, port=port,
                          path=(find 5), query=(find 7), frag=(find 9)}
                  end
             | _ => http{user="", password="", host="", port=default_port,
                         path=(find 5), query=(find 7), frag=(find 9)}
      in
         case (find 2) of
            "http"   => parse_http 80
          | "https"  => parse_http 8080
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
end
