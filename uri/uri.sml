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
