(* Simple test - parse an INI file of string demonstrations, then spit one
 * out of the dictionary showing simple access.
 *)
let
   val dict = Ini.parse "examples/strings.ini"

   (* This'll fail with the dictionary's exception if 'tab' doesn't exist
    * in the section 'section1'.
    *)
   val str  = IniDict.lookup dict "section1" "tab"
in
   print (hd str ^ "\n")
end
