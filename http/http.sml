(* $Id: http.sml,v 1.8 2004/08/11 16:22:06 chris Exp $ *)

(* Copyright (c) 2004, Chris Lumens
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 * - Redistributions of source code must retain the above copyright
 *   notice, this list of conditions and the following disclaimer.
 * - Redistributions in binary form must reproduce the above copyright
 *   notice, this list of conditions and the following disclaimer in the
 *   documentation and/or other materials provided with the distribution.
 * - The names of the contributors may not be used to endorse or promote
 *   products derived from this software without specific prior written
 *   permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 * IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 * NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *)
structure HTTP :> HTTP =
struct
   type dl = {filename: string, time: Time.time}

   exception StatusCode of int * string

   (* Return the value of the specified header. *)
   fun header (key, hdr::lst) =
      if String.isPrefix key hdr then 
         let
            open Substring

            (* Remove the header name and the colon. *)
            val value = dropl (fn ch => not (Char.isSpace ch)) (full hdr)
         in
            (* Remove leading space so we just have the header's value. *)
            SOME(string (dropl Char.isSpace value))
         end
      else
         header (key, lst)
     | header (key, []) = NONE

   (* Fetch the file described by the provided URI. *)
   fun get (URI.http{user, password, host, port, path, query, frag}) =
   let
      (* Connect to the given host on the given port via TCP.  Throws SysErr
       * if we are unable to make a connection.  Returns the opened socket.
       *)
      fun connect host port =
      let
         fun resolve host =
            #addr (SockUtil.resolveAddr {host=SockUtil.HostName(host),
                                         port=NONE})
            handle BadAddr => raise Fail ("unknown host: " ^ host)
      in 
         SockUtil.connectINetStrm {addr=(resolve host), port=port}
      end

      (* Close the connection and return nothing.  If conn is already
       * closed, handle SysErr by also returning nothing.
       *)
      fun close conn =
         Socket.close conn handle _ => ()

      (* Sends a request to the remote host.  Returns the number of
       * characters sent, throwing SysErr on error.
       *)
      fun send_request conn req =
         SockUtil.sendStr (conn, req)
         handle SysErr => ( print "could not send request" ; raise SysErr )

      (* Given an empty string and an open connection, read the headers
       * out of the beginning of the stream.  Returns the headers as a
       * list of strings and a connection pointing to the start of the
       * response body.  Note that the connection amy be closed on error.
       *)
      fun recv_headers (hdrs, conn) =
      let
         open Char Socket

         (* Read one byte out of the network connection, convert it to a
          * character, and return it.  We're safe doing the char
          * conversion here because we're still reading the headers which
          * are just going to be text information.
          *)
         val rd =
            (fn c => Byte.byteToChar (Word8Vector.sub (recvVec (c, 1), 0)))

         (* Split up a string into a list of strings on the newline. *)
         fun split str =
            String.tokens (fn ch => ch = #"\n")
                          (String.implode (List.filter (fn ch => ch <> #"\r")
                                                       (String.explode str)))

         (* Try to find the end of the HTTP response headers by stepping
          * through a state machine.  We accept only if "\r\n\r\n" is seen
          * and reject if any other character appears, returning
          * everything seen up to that point.  Yes, the return value is
          * backwards.
          *)
         fun state1 (f) c =
            case f c of #"\r" => state2 f c | ch => SOME(toString ch)
         and state2 (f) c =
            case f c of #"\n" => state3 f c | ch => SOME("\r" ^ (toString ch))
         and state3 (f) c =
            case f c of #"\r" => state4 f c | ch => SOME("\r\n" ^ (toString ch))
         and state4 (f) c =
            case f c of #"\n" => NONE | ch => SOME("\r\n\r" ^ (toString ch))
      in
         case state1 (rd) conn of
            SOME str => recv_headers (hdrs ^ str, conn)
          | NONE     => (split hdrs, conn)
      end
      handle SysErr => ([], conn)

      fun recv_body (hdrs, conn) =
      let
         (* Read the requested file out of the socket and write it to the
          * destination stream.  Closes the connection when we've got the
          * entire file.
          *)
         fun do_it (stream, conn) =
         let
            val vec = Socket.recvVec (conn, 8192)
         in
            if Word8Vector.length vec = 0 then
               ( close conn ; BinIO.closeOut stream )
            else
               ( BinIO.output (stream, vec) ; do_it (stream, conn) )
         end

         (* Return the HTTP status code from the header list.  The status line
          * must be at the head of the list, just like it'd be returned from
          * the server.
          *)
         fun status hdrs =
         let
            val tokens = String.tokens (fn ch => ch = #" ") (hd hdrs)
         in
            (Option.getOpt (Int.fromString (List.nth (tokens, 1)), 0),
             List.nth (tokens, 2))
         end handle _ => (0, "")

         (* Handle redirected URLs. *)
         fun redirected conn e hdrs =
            case header ("Location", hdrs) of
               SOME loc => (case URI.parse loc of
                               SOME uri => ( close conn ; get uri )
                             | NONE     => ( close conn ; raise e )
                           )
             | NONE     => ( close conn ; raise e )

         val filename = case path of
                           SOME p => (case OS.Path.file p of
                                         ""  => "index.html"
                                       | str => str)
                         | NONE     => "index.html"

         val (code, msg) = status hdrs
         val SCexn = StatusCode (code, msg)
         val Fexn  = Fail ("file " ^ filename ^ " already exists")
      in
         if code >= 400 then
            ( close conn ; raise SCexn )
         else
            if code >= 300 then
               redirected conn SCexn hdrs
            else
               (* Download file, returning full path and time taken. *)
               if not (OS.FileSys.access (filename, [])) then
                  let
                     val t = Timer.startRealTimer()
                  in
                     ( do_it (BinIO.openOut filename, conn) ;
                       {filename=(OS.FileSys.fullPath filename),
                        time=(Timer.checkRealTimer t)}
                     )
                  end
               else
                  ( close conn ; raise Fexn )
      end

      val conn = connect host (Option.getOpt (port, 80))
      val req  = "GET " ^ (Option.getOpt (path, "/")) ^ " HTTP/1.0\r\n" ^
                 "Host: " ^ host ^ "\r\n" ^
                 "User-Agent: SML/NJ Getter\r\n" ^
                 "Connection: close\r\n\r\n"
   in
      send_request conn req ; recv_body (recv_headers ("", conn))
   end

   | get (_) = raise URI.SchemeUnsupported
end
