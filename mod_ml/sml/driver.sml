(* This functor starts off the entire mod_ml process and hides the real
 * startup function's parameters from the user.  However, you must pass
 * the functor a configuration structure that matches the signature listed
 * below.  At the bare minimum, this structure must include a port to
 * listen on, a list of files to load, and a list of CM modules to
 * autoload.
 *
 * $Id: driver.sml,v 1.1 2004/01/04 17:53:19 chris Exp $
 *)
functor Driver (C: sig
                      val port: int
                      val preload: string list
                      val autoload: string list
                   end) =
struct
   fun run () =
      Network.run C.autoload C.preload C.port
end
