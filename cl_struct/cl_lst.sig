(* List manipulation sub-signature.
 *
 * $Id: cl_lst.sig,v 1.2 2004/06/25 02:03:39 chris Exp $
 *)
signature CL_LST =
sig
   (* interleave l a
    * Turn the list [l1, l2, ..., ln] into [l1, a, l2, a, ..., a, ln].
    * Raises Empty if l is nil.
    *)
   val interleave: 'a list -> 'a -> 'a list

   (* split l n
    * Split l into multiple lists, each of which has n elements.  Note
    * that the last list may be shorter if length l % n != 0.  Raises
    * Empty if l is nil.
    *)
   val split: int -> 'a list -> 'a list list

   (* takewhile f l
    * Take all elements from the head of l for which the function f
    * returns true.  Stops on the first element which returns false.
    *)
   val takewhile: ('a -> bool) -> 'a list -> 'a list
end
