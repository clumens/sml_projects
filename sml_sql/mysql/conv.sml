(* Convert SQL data types in string representations into native SML types.
 * On error, throw an exception to our client.
 *
 * $Id: conv.sml,v 1.1 2004/01/04 22:15:43 chris Exp $
 *)
structure Conv :> CONV =
struct
   (* Convert a string to a boolean type. *)
   fun toBoolean ("Y"|"y"|"1"|"TRUE"|"T"|"true") = true
     | toBoolean _ = false

   (* Convert a string into an integer. *)
   fun toInteger str = Int.fromString str

   (* Intercept the Overflow exception and return NONE instead, which
    * makes this function more of a second attempt for toInteger than a
    * standalone.
    *)
   fun toLargeInt str = LargeInt.fromString str
   handle Overflow => NONE

   (* Convert from SQL's "YYYY-MM-DD HH:MM:SS" to SML's Date format.  Note
    * that while date types suck everywhere, they suck less under ML.
    *)
   fun toDate str =
   let
      open Substring
      open Date

      (* Convert a substring into an integer. *)
      val toInt = (fn (substr) => case Int.fromString (string substr) of
                                     SOME i => i
                                   | NONE   => raise Date
                  )

      (* Given an integer, convert it into a Date.month type. *)
      fun toMonth n =
         if n > 12 orelse n <= 0 then raise Date
         else List.nth ([Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct,
                         Nov, Dec], n)
     
      (* Remove any leading and trailing whitespace from the string.  Then,
       * split it on the internal spacing into date and time components.
       * Finally, split those two lists on their delimiters into
       * individual date and time elements.
       *)
      val tokenized = tokens (fn ch => ch = #" ")
                             (dropr Char.isSpace
                                    (dropl Char.isSpace (full str)))
      val dateLst = tokens (fn ch => ch = #"-") (List.nth(tokenized, 0))
      val timeLst = tokens (fn ch => ch = #":") (List.nth(tokenized, 1))
   in
      Date.date{year = (toInt) (List.nth (dateLst, 0)),
                month = toMonth ((toInt) (List.nth (dateLst, 1))),
                day = (toInt) (List.nth (dateLst, 2)),
                hour = (toInt) (List.nth (timeLst, 0)),
                minute = (toInt) (List.nth (timeLst, 1)),
                second = (toInt) (List.nth (timeLst, 2)),
                offset = NONE}
   end
end
