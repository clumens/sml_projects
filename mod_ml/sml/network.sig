(* Interface to the network layer.  This is not for general consumption.
 * See the Driver structure for that.
 *
 * $Id
 *)
signature NETWORK =
sig
   (* Start the networking.  Provide the autoload module list, the preload
    * module list, and the port to listen on.
    *)
   val run: string list -> string list -> int -> unit
end
