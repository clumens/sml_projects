(* $Id: conv.sig,v 1.1 2004/01/04 22:15:43 chris Exp $ *)
signature CONV =
sig
   (* Convert a string into a boolean value. *)
   val toBoolean: string -> bool

   (* Convert a string into an integer value.  If the result is too big to
    * fit into an integer, an Overflow exception will be raised.  In that
    * case, try toLargeInt instead.
    *)
   val toInteger: string -> int option

   (* Convert a string into a large integer.  If the result is too big to
    * fit into a large integer or if the conversion failed, the option
    * type NONE will be returned.
    *)
   val toLargeInt: string -> LargeInt.int option

   (* Throws Date.Date if any part of the date string is malformed.  Note
    * that to handle MySQL's TIMESTAMP type, you'll need to have it
    * converted into DATETIME format first.
    *)
   val toDate: string -> Date.date
end
