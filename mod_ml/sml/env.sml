(* This structure manages environment tables, such as the one handed to us
 * by Apache on each request.  It can also be used to make tables of
 * cookies, headers, parameters, or anything else.
 *
 * $Id: env.sml,v 1.1 2004/01/04 17:53:19 chris Exp $
 *)
structure Env :> ENV =
struct
   exception NotFound

   type env = (string, string) HashTable.hash_table

   (* Build an empty environment. *)
   fun mk_env () =
      HashTable.mkTable (HashString.hashString, op =) (128, NotFound)
   
   (* Build the initial dictionary from a string, where each even line is
    * a key and each odd line is a value.  The list of pairs is terminated
    * by a "end\n" with no value.
    *)
   fun init_env env str =
   let
      (* Given a list of strings, convert it into a list of (key, value)
       * pairs.  If we only have a key with no value, throw away the key
       * and return the list.  On the other hand, if we have a null key
       * then we're dealing with a blank value somewhere.  Discard the
       * bogus key and resync on the rest of the list.
       *)
      fun mk_pair_lst (key::value::lst, pair_lst) =
             if key = "" then mk_pair_lst ([value] @ lst, pair_lst)
             else             mk_pair_lst (lst, (key, value)::pair_lst)
        | mk_pair_lst (key::[], pair_lst) = pair_lst
        | mk_pair_lst ([], pair_lst) = pair_lst
   in
      (* Insert each (key, value) mapping into the dictionary. *)
      ignore (map (HashTable.insert env)
                  (mk_pair_lst ((String.fields (fn ch => ch = #"\n") str),
                                [])))
   end

   (* Wrappers around the dictionary representation. *)
   val clear = HashTable.clear
   val insert = HashTable.insert
   val lookup = HashTable.lookup
   val find = HashTable.find
   val remove = HashTable.remove
   val listItems = HashTable.listItems
   val listItemsi = HashTable.listItemsi
end
