(* $Id: websuck.sml,v 1.1 2004/08/13 02:53:07 chris Exp $ *)

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

(* This is a demo of how to use the HTTP structure to fetch URIs from web
 * servers.  It's intended to show off the features of HTTP and
 * demonstrate how to interact with it.  This of this as a reference
 * implementation of a wget-like program for SML.
 *)
structure Websuck :> sig
   val main: string * string list -> OS.Process.status
end =
struct
   fun dl uri =
   let
      (* Print an error message and quit. *)
      fun die str =
         ( print ("Invalid URI: " ^ str ^ "\n") ; OS.Process.terminate 1 )

      (* Download the requested URI, printing out a helpful message about
       * the name of the file we wrote, how long it took to download, and
       * the speed.
       *)
      fun do_it uri =
      let
         val {filename, time} = HTTP.get uri
         val size = OS.FileSys.fileSize filename
         val rate = ((LargeReal.fromInt size) / 1024.0) / (Time.toReal time)
      in
         ( print ("Downloaded to: " ^ filename ^ "\n" ^
                  "Completed in: " ^ (Time.toString time) ^ " seconds " ^
                  "at " ^ (LargeReal.toString rate) ^ " kbps\n") ;
           0 )
      end
      handle HTTP.StatusCode (_, msg) =>
         ( print ("get failed with message: " ^ msg ^ "\n") ; 1 )
   in
      (* We can only download from web servers, so reject any URIs that
       * are not HTTP.
       *)
      case URI.parse uri of
         uri' as SOME(URI.http{...}) => do_it (Option.valOf uri')
       | _ => die uri
   end

   (* Print a help message and quit. *)
   fun help () =
      ( print "usage: websuck <url>\n" ; OS.Process.terminate 1 )

   fun main (prog, arg::[]) =
         dl arg
     | main (prog, arg::arglist) =
         help()
     | main (prog, []) =
         help()
end
