(* Utility functions to generate SQL query statements.  Each function in this
 * structure creates a statement that accomplishes one task, from a set of
 * parameters.  This also provides a central point for user input to be
 * cleansed before hitting the database.
 *
 * $Id: query.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure Query :> QUERY =
struct
   datatype query =
      insertUser of string * string * string * string * bool * bool * bool
    | insertOwner of string * string

   fun toString (insertUser(user, pass, name, email, comment, upload, admin)) =
          "INSERT INTO Site_User VALUES (\"" ^
          MySQL.clean user ^ "\", " ^
          "SHA(\"" ^ MySQL.clean pass ^ "\"), " ^
          "\"" ^ MySQL.clean name ^ "\", " ^
          "\"" ^ MySQL.clean email ^ "\", " ^
          ( if comment = false then "0, " else "1, " ) ^
          ( if upload = false then "0, " else "1, " ) ^
          ( if admin = false then "0)" else "1)" )

     | toString (insertOwner(owner, dir)) =
          "INSERT INTO Ownership VALUES (\"" ^
          MySQL.clean owner ^ "\", " ^
          "\"" ^ MySQL.clean (Dir.add_slash dir) ^ "\")"
end
