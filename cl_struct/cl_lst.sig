(* List manipulation sub-signature.
 *
 * $Id: cl_lst.sig,v 1.1.1.1 2004/01/04 17:53:19 chris Exp $
 *)
signature CL_LST =
sig
   (* Turn the list [a1, a2, ..., an] into [a1, b, a2, b, ..., b, an] *)
   val interleave: 'a list -> 'a -> 'a list

   (* Split the list into multiple lists, each of which has n elements.
    * Note that the last list may be shorter if length list % n != 0.
    *)
   val split: int -> 'a list -> 'a list list

   (* Take all elements from the head of the list for which the function
    * returns true.  Stops on the first element which returns false.
    *)
   val takewhile: ('a -> bool) -> 'a list -> 'a list
end
