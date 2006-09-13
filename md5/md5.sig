(* Structure to calculate MD5 sums for files.
 *
 * $Id: md5.sig,v 1.4 2006/09/13 03:20:15 chris Exp $
 *)

(* Copyright (c) 2004, 2006 Chris Lumens
 * All rights reserved.
 *
 * See the COPYING file included in this distribution for the license.
 *)
signature MD5 =
sig
   val sum: string -> string
end
