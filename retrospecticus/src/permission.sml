(* Handle checking that the current user has permission to do whatever
 * they are trying to do.
 *
 * $Id: permission.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure Permission :> PERMISSION =
struct
   (* A user may create a new collection if they are also the owner of the
    * parent collection.  Note that this makes starting out a little odd,
    * so when we make a user who can upload, we need to make sure to
    * create their top-level directory so everything can go from there.
    *)
   fun user_may_create parent owner =
   let
      val own_q = "login_name=\"" ^ owner ^ "\" AND directory=\"" ^
                   Dir.add_slash parent ^ "\""
      val may_q = "SELECT may_upload FROM Site_User WHERE login_name=\"" ^
                  owner ^ "\""
   in
      case hd (hd (MySQL.map Browser.conn (fn x => x) may_q)) of
         "0" => false
         | _ => ( case MySQL.count Browser.conn "Ownership" own_q of
                     SOME i => if i > 0 then true else false
                   | _      => false )
   end

   (* Add a new entry into the Ownership table for the new collection. *)
   fun new_collection dir owner =
   let
      val q = Query.insertOwner (owner, dir)
   in
      MySQL.app Browser.conn (fn x => x) (Query.toString q)
   end
end
