(* Manage and manipulate collections.  A collection is the analogue of a
 * directory on a filesystem - it can hold photos as well as other
 * collections, allowing arbitrarily complex structures.
 *
 * $Id: collection.sig,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
signature COLLECTION =
sig
   (* Throw this when we're unable to create a collection.  This either
    * means we can't make the directory, the name is already taken, or
    * any other error.
    *)
   exception CollectionErr

   (* We have names for displaying in the web browser and dir_name which
    * is the filesystem representation.
    *)
   type collection = {owner: string, name: string, dir_name: string,
                      parent: string}

   val to_list: string -> string list
   val create: collection -> unit
   val valid_input: collection -> bool
end
