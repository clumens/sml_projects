(* This structure is responsible for getting the whole photo browser
 * system up and running.  Simply call Browser.run() and the system
 * will get going.  We use the mod_ml functor to initialize the
 * interface to the running Apache process.
 *
 * $Id: browser.sml,v 1.1.1.1 2004/01/04 17:53:20 chris Exp $
 *)
structure Browser =
struct
   (* Make the mod_ml driver. *)
   structure D = Driver(Config)

   val login_env = Env.mk_env()

   (* Our connection to the database. *)
   val conn = MySQL.openConn ("root", "cockblock", "PhotoTest")

   fun run () =
      D.run()
end
