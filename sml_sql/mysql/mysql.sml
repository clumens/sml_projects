(* $Id: mysql.sml,v 1.1 2004/01/04 22:15:44 chris Exp $ *)
structure MySQL :> MYSQL =
struct
   type conn = (S_st_mysql.tag, C.rw) C.su_obj C.ptr'

   exception SqlExn of string

   (* Did an error occur? *)
   fun err conn =
      if Word32.toInt (F_mysql_errno.f' conn) = 0 then
         false
      else
         true

   (* After calling the above to determine if an error occurred, this
    * extracts the error string.
    *)
   fun errStr conn =
      ZString.toML' (F_mysql_error.f' conn)

   (* How many columns are in the result set? *)
   fun numColumns resultSet =
      Word32.toInt (F_mysql_num_fields.f' resultSet)

   (* Open a connection to a database server running on the local machine. *)
   fun openConn(user, password, db) =
   let
      val host' = ZString.dupML' "localhost"
      val user' = ZString.dupML' user
      val password' = ZString.dupML' password
      val db' = ZString.dupML' db

      val mysql = F_mysql_init.f' C.Ptr.null'

      val zero = Word32.fromInt 0

      val conn = F_mysql_real_connect.f' (mysql, host', user', password',
                                          db', zero, C.Ptr.null', zero)
   in
      (* Free up those strings. *)
      app C.free' [host', user', password', db'] ;

      if C.Ptr.isNull' conn then
         raise SqlExn "Unable to establish connection"
      else
         if err mysql then
            raise SqlExn (errStr mysql)
         else
            conn
   end

   (* Close a connection previously opened with openConn. *)
   fun closeConn conn =
      F_mysql_close.f' conn

   (* Apply the function f to the result set of performing query q,
    * returning a list of the results.  Note that f should expect to get a
    * list where each element is a list of strings, each string
    * representing one column from the result row.  This function does all
    * the heavy work of most of our other query functions.
    *)
   fun map conn f q =
   let
      val _ = F_mysql_query.f' (conn, ZString.dupML' q)
   in
      if err conn then
         raise SqlExn (errStr conn)
      else
         let
            val results = F_mysql_store_result.f' conn

            (* Convert the result set into a list of results, one row
             * at a time.  res is of the MYSQL_RES type and contains the
             * result set from the query.  We move a cursor through it
             * extracting one row at a time, or NULL when we're at the
             * end.
             *)
            fun rows (res, lst) =
            let
               (* Turn each element of the result row into an ML
                * string, then make a list of those and return it.
                *)
               fun row2lst row =
               let
                  fun ele2MLstr ndx =
                  let
                     val ptr = C.Get.ptr' (C.Ptr.sub' C.S.ptr (row, ndx))
                  in
                     if C.Ptr.isNull' ptr then ""
                     else ZString.toML' ptr
                  end
               in
                  List.tabulate (numColumns results, ele2MLstr)
               end

               val r = F_mysql_fetch_row.f' res
            in
               if C.Ptr.isNull' r then
                  rev lst
               else
                  rows (res, row2lst r::lst)
            end
         in
            (* We don't want to throw an exception here because INSERT
             * statements cause mysql_store_result to return NULL.
             *)
            if C.Ptr.isNull' results then
               []
            else
               List.map f (rows(results, []))
         end
   end

   (* Same as map, but throw the results on the floor. *)
   fun app conn f q =
      ignore (map conn f q)

   (* Return a list of the names of the table's columns. *)
   fun fieldNames conn table =
      map conn (fn lst => hd lst) ("DESCRIBE " ^ table)

   (* Run a query on a connection, returning a single integer value. *)
   fun intValue conn q =
      Conv.toInteger (hd (map conn (fn lst => hd lst) q))
   handle SqlExn str => raise SqlExn (str ^ "\n<br>Query = " ^ q)

   (* Return the number of matches found in a table. *)
   fun count conn tbl whereClause =
      intValue conn ("SELECT COUNT(*) FROM " ^ tbl ^ " WHERE " ^ whereClause)

   (* Return the maximum value from a column, or -1 if the column's empty. *)
   fun max conn tbl col =
      case intValue conn ("SELECT MAX(" ^ col ^ ") FROM " ^ tbl) of
         SOME i => i
       | _      => ~1

   (* Escape any possibly dangerous characters from user input. *)
   fun clean str =
      String.translate (fn ch => case ch of
                                    #"\"" => "\\\""
                                  | #"'" => "\\'"
                                  | _     => String.str ch)
                       str
end
