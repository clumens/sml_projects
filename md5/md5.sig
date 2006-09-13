(* Structure to calculate MD5 sums for files.
 *
 * $Id: md5.sig,v 1.3 2006/09/13 02:51:38 chris Exp $
 *)

(* Copyright (c) 2004, 2006 Chris Lumens
 * All rights reserved.
 *
 * See the COPYING file included in this distribution for the license.
 *)
signature MD5 =
sig
   val sum: string -> unit
end
