(* $Id: mysql.sig,v 1.1 2004/01/04 22:15:43 chris Exp $ *)
signature MYSQL =
sig
   (* Database connection type. *)
   type conn
   
   (* General purpose exception for when something bad happens. *)
   exception SqlExn of string

   (* Open a connection to a local MySQL process given:
    *    user, password, db
    *)
   val openConn: (string * string * string) -> conn

   (* Close an open database connection. *)
   val closeConn: conn -> unit

   (* Given an open connection, a function, and a query:  apply the
    * function to each row of the result set from running the query.
    * Return the results in list form.
    *)
   val map: conn -> (string list -> 'a) -> string -> 'a list

   (* Given an open connection, a function, and a query:  apply the function
    * to each row of the result set from running the query.  Throw away
    * the results.
    *)
   val app: conn -> (string list -> 'a) -> string -> unit

   (* Given an open connection and a table name, return a list of the
    * names for the table's columns.
    *)
   val fieldNames: conn -> string -> string list

   (* Given an open connection, a table name, and the where clause of a
    * select statement, return the number of results.
    *)
   val count: conn -> string -> string -> int option

   (* Given an open connection, a table name, and a column name, return
    * the maximum value out of that column.
    *)
   val max: conn -> string -> string -> int

   (* Make sure any dangerous characters are escaped.  Make sure to run
    * any strings coming from user input through this function before
    * making an SQL query out of them.
    *)
   val clean: string -> string
end
