(* $Id: dict.sml,v 1.3 2004/08/08 02:25:27 chris Exp $ *)

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

structure IniDict =
struct
   (* Thrown by the hash table internals. *)
   exception NotFound

   (* A dictionary that, given a key, returns the value stored there. *)
   type setting_dict = (string, string list) HashTable.hash_table

   (* A dictionary that, given a string, returns the dictionary for that
    * section.
    *)
   type section_dict = (string, setting_dict) HashTable.hash_table

   (* Look up a key in the dictionary.  If it exists, append the value to
    * the existing one.  If it does not exist, create a new mapping.
    *)
   fun append dict (key, value) =
      case (HashTable.find dict key) of
         SOME old_value => HashTable.insert dict (key, [value] @ old_value)
       | NONE           => HashTable.insert dict (key, [value])

   (* Look for the item given by key under the given section.  Returns
    * NONE if the item doesn't exist.
    *)
   fun find dict section key =
      case HashTable.find dict section of
         SOME s => HashTable.find s key
       | NONE   => NONE

   (* Look for the item given by key under the given section.  Raises the
    * table's exception if the item doesn't exist.
    *)
   fun lookup dict section key =
      HashTable.lookup dict (HashTable.lookup dict section)

   (* Create a blank dictionary. *)
   fun mkDict () =
      HashTable.mkTable (HashString.hashString, op =) (47, NotFound)

   (* Convert an ini dictionary into a string suitable for printing. *)
   fun toString dict =
   let
      val I = fn i => i

      val sect_str = fn (k, v, str) => str ^ "\t" ^ k ^ " => " ^
                                       (ListFormat.listToString I v) ^
                                       "\n"
   in
      HashTable.foldi (fn (k, v, str) => str ^ k ^ ":\n" ^
                                         (HashTable.foldi sect_str "" v))
                      "" dict
   end
end
