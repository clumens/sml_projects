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
