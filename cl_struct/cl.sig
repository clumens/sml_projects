(* Top-level signature for my utility structure.  Right now, this appears
 * to only contain other structures.  Well, I do like organization.
 *
 * $Id: cl.sig,v 1.1.1.1 2004/01/04 17:53:19 chris Exp $
 *)
signature CL =
sig
   structure Lst: CL_LST
end
