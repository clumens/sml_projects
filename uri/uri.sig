(* Structure to manipulate and verify URIs, in accordance with RFC 2396.
 *
 * $Id: uri.sig,v 1.5 2004/07/27 13:24:13 chris Exp $
 *)

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
signature URI =
sig
   datatype URI = ftp of {user: string option, password: string option,
                          host: string, port: int option, path: string option}
                | http of {user: string option, password: string option,
                           host: string, port: int option, path: string option,
                           query: string option, frag: string option}
                | unknown of {scheme: string, auth: string, path: string option,
                              query: string option, frag: string option}

   (* Given a string, return the appropriate URI from the above datatype.
    * For URIs that are understood by this parser, it will return the
    * appropriate above constructor with all the extra information it can
    * determine.  For unknown URIs, the unknown constructor is used.  If
    * no URI can be found in the string, the NONE option type is returned.
    *)
   val parse: string -> URI option

   (* Convert a URI into a string. *)
   val toString: URI -> string
end
