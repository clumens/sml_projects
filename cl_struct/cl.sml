(* Utility functions I've developed that don't belong anywhere else.
 *
 * $Id: cl.sml,v 1.2 2004/06/25 01:57:58 chris Exp $
 *)
structure Cl :> CL =
struct
   structure Lst :> CL_LST =
   struct
      fun interleave lst v =
      let
         fun do_it (ele::in_lst) out_lst =
                do_it in_lst (v::ele::out_lst)
           | do_it ([]) out_lst =
                rev (tl out_lst)
      in
         do_it lst []
      end

      fun split n [] =
         raise Empty
        | split n lst =
      let
         fun do_split n lst retval =
            if length lst < n then
               if null lst then rev retval
               else rev (lst::retval)
            else
               do_split n (List.drop (lst, n)) (List.take (lst, n)::retval)
      in
         if n <= 0 then [lst]
         else do_split n lst []
      end

      fun takewhile f [] = []
        | takewhile f (x::xs) =
             if f x then x::takewhile f xs
             else []
   end
end
