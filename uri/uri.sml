(* $Id: uri.sml,v 1.6 2004/07/27 13:24:13 chris Exp $ *)

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
   datatype URI = ftp of {user: string option, password: string option,
                          host: string, port: int option, path: string option}
                | http of {user: string option, password: string option,
                           host: string, port: int option, path: string option,
                           query: string option, frag: string option}
                | unknown of {scheme: string, auth: string, path: string option,
                              query: string option, frag: string option}

   structure DFA = RegExpFn(structure P=AwkSyntax
                            structure E=BackTrackEngine)

   fun parse str =
   let
      fun match str tree =
      let
         fun find n =
            case MatchTree.nth (tree, n) of
               SOME {pos, len} =>
                  let
                     val sub = String.substring (str, pos, len)
                  in
                     if sub = "" then NONE else SOME(sub)
                  end
             | NONE => NONE

         fun find' n =
            Option.getOpt (find n, "")

         fun auth str =
            case (String.tokens (fn ch => ch = #":") str) of
               n::[]    => (SOME n, NONE)
             | n::p::[] => (SOME n, SOME p)
             | _        => (NONE, NONE)

         fun remote str =
            case (String.tokens (fn ch => ch = #":") str) of
               h::[]    => (h, NONE)
             | h::p::[] => (h, Int.fromString p)
             | _        => ("", NONE)

         fun parse_ftp () =
            case (String.tokens (fn ch => ch = #"@") (find' 4)) of
               r::[] =>
                  let
                     val (host, port) = remote r
                  in
                     SOME(ftp{user=NONE, password=NONE, host=host, port=port,
                              path=(find 5)})
                  end
             | a::r::[] =>
                  let
                     val (user, pass) = auth a
                     val (host, port) = remote r
                  in
                     SOME(ftp{user=user, password=pass, host=host, port=port,
                              path=(find 5)})
                  end
             | _ => NONE

         fun parse_http () =
            case (String.tokens (fn ch => ch = #"@") (find' 4)) of
               r::[] =>
                  let
                     val (host, port) = remote r
                  in
                     SOME(http{user=NONE, password=NONE, host=host, port=port,
                               path=(find 5), query=(find 7), frag=(find 9)})
                  end
             | a::r::[] =>
                  let
                     val (user, pass) = auth a
                     val (host, port) = remote r
                  in
                     SOME(http{user=user, password=pass, host=host,
                               port=port, path=(find 5), query=(find 7),
                               frag=(find 9)})
                  end
             | _ => NONE
      in
         case (find' 2) of
            "ftp"    => parse_ftp ()
          | "http"   => parse_http ()
          | s        => SOME(unknown{scheme=s, auth=(find' 4), path=(find 5),
                                     query=(find 7), frag=(find 9)})
      end

      (* Regular expression from RFC 2396, appendix B. *)
      val re = DFA.compileString "^(([^:/?#]+):)?(//([^/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?"
   in
      case StringCvt.scanString (DFA.find re) str of
         SOME tree => match str tree
       | NONE      => NONE
   end

   fun toString uri =
   let
      (* Special version of Option.map. *)
      fun mapEmpty f opt =
         case opt of
            SOME v => f v
          | NONE   => ""

      (* Yes, this is the identity function. *)
      fun I i = i

      (* Make chunks of the return string. *)
      fun F frag = "#" ^ frag
      fun P port = ":" ^ Int.toString port
      fun Q query = "?" ^ query

      (* Make the user & password portion of the return string. *)
      fun cred_string (user, password) =
         case (user, password) of
            (SOME u, SOME p) => u ^ ":" ^ p ^ "@"
          | (SOME u, NONE)   => u ^ "@"
          | _                => ""

      fun do_it (ftp{user, password, host, port, path}) =
         "ftp://" ^ cred_string (user, password) ^ host ^
         mapEmpty P port ^ mapEmpty I path

        | do_it (http{user, password, host, port, path, query, frag}) =
         "http://" ^ host ^ cred_string (user, password) ^
         mapEmpty P port ^ mapEmpty I path ^ mapEmpty Q query ^
         mapEmpty F frag

        | do_it (unknown{scheme, auth, path, query, frag}) =
         scheme ^ "://" ^ auth ^ mapEmpty I path ^
         mapEmpty Q query ^ mapEmpty F frag
   in
      do_it uri
   end
end
