(* Demonstrates parsing an INI file and then spitting the parsed version
 * back out as a string suitable for writing to a file.  Note that the
 * results will be in a different order than the input.
 *)
let
   val dict = Ini.parse "examples/basic.ini"
   val str  = Ini.toString dict
in
   print str
end
