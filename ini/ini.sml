(* $Id: ini.sml,v 1.2 2004/08/07 05:41:47 chris Exp $ *)

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
structure Ini =
struct
   structure IniParserLrVals =
     IniParserLrValsFun(structure Token = LrParser.Token)

   structure IniLex = IniLexFun(structure Tokens = IniParserLrVals.Tokens);

   structure IniParser = Join(structure LrParser = LrParser
                              structure ParserData = IniParserLrVals.ParserData
                              structure Lex = IniLex)

   fun parse filename =
   let
      fun lex get =
         LrParser.Stream.streamify (IniLex.makeLexer get)

      fun print_error (s, i:int, _) =
         TextIO.output(TextIO.stdOut,
                       "Error, line " ^ (Int.toString i) ^ ", " ^ s ^ "\n")

      val file = TextIO.openIn filename

      fun get _ = TextIO.input file
   in
      IniParser.parse (0, lex get, print_error, ()) ;
      TextIO.closeIn file
   end
end
