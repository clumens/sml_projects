(* Interface with mod_ml.  This structure opens a socket that mod_ml can
 * connect to and manages that connection.  We receive environments from
 * Apache and use these environments to translate pages.  We then send
 * those pages and headers back to Apache, taking care to handle error
 * cases by sending blank HTML strings.
 *
 * $Id: network.sml,v 1.1.1.1 2004/01/04 17:53:19 chris Exp $
 *)
structure Network :> NETWORK =
struct
   (* Bind a port to a socket and listen on that port for incoming
    * connections.  Pass off the connection accepting part to a helper
    * function.  Note: we're a little sloppy with exception handling here.
    *)
   fun ml_server port listener =
   let
      (* Accept a connection from the remote host, receive the string, and
       * dispatch it for handling.  Rinse and repeat.
       *)
      fun accept listener =
      let
         (* Send the built HTML page back to the web server. *)
         fun reply conn msg =
         let
            val buf = {buf = Byte.stringToBytes msg, i=0, sz=NONE}
         in
            Socket.sendVec (conn, buf) ; Socket.close conn
         end

         (* Read the string one chunk at a time out of the socket,
          * building up the full string as we go along.  Once we've read
          * the terminator, we can process it.
          *)
         fun recv conn str =
         let
            val msg = Byte.bytesToString (Socket.recvVec (conn, 100))
            val str' = str ^ msg
         in
            if (String.isSuffix "end\n" str') then str'
            else recv conn str'
         end
      
         (* conn is an active socket. *)
         val (conn, _) = Socket.accept listener
         val response  = Apache.translate (recv conn "")
      in
         reply conn response ;
         accept listener
      end
   in
      ( Socket.Ctl.setREUSEADDR (listener, true) ;
        Socket.bind (listener, INetSock.any port) ;
        Socket.listen (listener, 16) ;
        accept listener
      )
      handle
         OS.SysErr (msg, _) => (Socket.close listener ; print (msg ^ "\n"))
   end

   (* Fire up the networking. *)
   fun run autoload preload port =
   let
      (* Sockets start as passive, meaning unconnected.  Once a connection
       * is made, we get an active socket to the remote host.
       *)
      val sock: Socket.passive INetSock.stream_sock = INetSock.TCP.socket()
   in
      (* Load in any structures the user wants their pages to access. *)
      app CM.autoload autoload ;
      app use preload ;
      ml_server port sock
   end
   handle OS.SysErr (msg, _) => print (msg ^ "\n")
end
