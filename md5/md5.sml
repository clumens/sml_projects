(* $Id: md5.sml,v 1.1 2004/09/30 02:26:07 chris Exp $ *)

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
structure MD5 :> MD5 =
struct
   structure LW = LargeWord
   structure W8  = Word8
   structure W8V = Word8Vector

   type state = {size: LW.word, digest: LW.word vector}

   (* Mysterious initialization constants. *)
   fun init () =
      {size=0w0, digest= #[0wx67452301, 0wxefcdab89, 0wx98badcfe,
                           0wx10325476]}: state

   (* Convert the LargeWord large into a vector of LargeWords, each
    * representing one byte of large.
    *)
   fun unpack large =
      #[LW.>> (LW.andb (large, 0wxff000000), 0w24),
        LW.>> (LW.andb (large, 0wxff0000), 0w16),
        LW.>> (LW.andb (large, 0wxff00), 0w8),
        LW.andb (large, 0wxff)]

   (* digest is a vector of four LargeWords, and vec is a Word8Vector. *)
   fun transform {size, digest} vec =
   let
      (* Core MD5 algorithms functions. *)
      val F1 = fn (x, y, z) => LW.xorb (z, LW.andb (x, LW.xorb(y, z)))
      val F2 = fn (x, y, z) => F1(z, x, y)
      val F3 = fn (x, y, z) => LW.xorb (x, LW.xorb (y, z))
      val F4 = fn (x, y, z) => LW.xorb (y, LW.orb (x, LW.notb z))

      (* MD5 algorithm stepping function - applies one of the above four
       * functions to the rest of the arguments, returning the new value of
       * "w".
       *)
      fun step f (w, x, y, z, input, s) =
      let
         val w' = w + f(x, y, z) + input
      in
         LW.orb (LW.<< (w', s), LW.>> (w', 0w32 - s)) + x
      end

      (* All these MD5 step round functions are the same form - both take in
       * the same vector of 16 words from the input file and a vector of four
       * words representing the current digest state.  Parameter order allows
       * us to compose curried versions of all these roundX functions together
       * into one operation.
       *)
      fun round1 input v =
      let
         open Vector

         val f = (step F1)

         val a = sub (v, 0)
         val b = sub (v, 1)
         val c = sub (v, 2)
         val d = sub (v, 3)

         val a' = f (a,  b,  c,  d,  sub (input, 0)  + 0wxd76aa478, 0w7)
         val d' = f (d,  a', b,  c,  sub (input, 1)  + 0wxe8c7b756, 0w12)
         val c' = f (c,  d', a', b,  sub (input, 2)  + 0wx242070db, 0w17)
         val b' = f (b,  c', d', a', sub (input, 3)  + 0wxc1bdceee, 0w22)

         val a' = f (a', b', c', d', sub (input, 4)  + 0wxf57c0faf, 0w7)
         val d' = f (d', a', b', c', sub (input, 5)  + 0wx4787c62a, 0w12)
         val c' = f (c', d', a', b', sub (input, 6)  + 0wxa8304613, 0w17)
         val b' = f (b', c', d', a', sub (input, 7)  + 0wxfd469501, 0w22)

         val a' = f (a', b', c', d', sub (input, 8)  + 0wx698098d8, 0w7)
         val d' = f (d', a', b', c', sub (input, 9)  + 0wx8b44f7af, 0w12)
         val c' = f (c', d', a', b', sub (input, 10) + 0wxffff5bb1, 0w17)
         val b' = f (b', c', d', a', sub (input, 11) + 0wx895cd7be, 0w22)

         val a' = f (a', b', c', d', sub (input, 12) + 0wx6b901122, 0w7)
         val d' = f (d', a', b', c', sub (input, 13) + 0wxfd987193, 0w12)
         val c' = f (c', d', a', b', sub (input, 14) + 0wxa679438e, 0w17)
         val b' = f (b', c', d', a', sub (input, 15) + 0wx49b40821, 0w22)
      in
         #[a+a', b+b', c+c', d+d']
      end

      fun round2 input v =
      let
         open Vector

         val f = (step F2)

         val a = sub (v, 0)
         val b = sub (v, 1)
         val c = sub (v, 2)
         val d = sub (v, 3)

         val a' = f (a,  b,  c,  d,  sub (input, 1)  + 0wxf61e2562, 0w5)
         val d' = f (d,  a', b,  c,  sub (input, 6)  + 0wxc040b340, 0w9)
         val c' = f (c,  d', a', b,  sub (input, 11) + 0wx265e5a51, 0w14)
         val b' = f (b,  c', d', a', sub (input, 0)  + 0wxe9b6c7aa, 0w20)

         val a' = f (a', b', c', d', sub (input, 5)  + 0wxd62f105d, 0w5)
         val d' = f (d', a', b', c', sub (input, 10) + 0wx02441453, 0w9)
         val c' = f (c', d', a', b', sub (input, 15) + 0wxd8a1e681, 0w14)
         val b' = f (b', c', d', a', sub (input, 4)  + 0wxe7d3fbc8, 0w20)

         val a' = f (a', b', c', d', sub (input, 9)  + 0wx21e1cde6, 0w5)
         val d' = f (d', a', b', c', sub (input, 14) + 0wxc33707d6, 0w9)
         val c' = f (c', d', a', b', sub (input, 3)  + 0wxf4d50d87, 0w14)
         val b' = f (b', c', d', a', sub (input, 8)  + 0wx455a14ed, 0w20)

         val a' = f (a', b', c', d', sub (input, 13) + 0wxa9e3e905, 0w5)
         val d' = f (d', a', b', c', sub (input, 2)  + 0wxfcefa3f8, 0w9)
         val c' = f (c', d', a', b', sub (input, 7)  + 0wx676f02d9, 0w14)
         val b' = f (b', c', d', a', sub (input, 12) + 0wx8d2a4c8a, 0w20)
      in
         #[a+a', b+b', c+c', d+d']
      end

      fun round3 input v =
      let
         open Vector

         val f = (step F3)

         val a = sub (v, 0)
         val b = sub (v, 1)
         val c = sub (v, 2)
         val d = sub (v, 3)

         val a' = f (a,  b,  c,  d,  sub (input, 5)  + 0wxfffa3942, 0w4)
         val d' = f (d,  a', b,  c,  sub (input, 8)  + 0wx8771f681, 0w11)
         val c' = f (c,  d', a', b,  sub (input, 11) + 0wx6d9d6122, 0w16)
         val b' = f (b,  c', d', a', sub (input, 14) + 0wxfde5380c, 0w23)

         val a' = f (a', b', c', d', sub (input, 1)  + 0wxa4beea44, 0w4)
         val d' = f (d', a', b', c', sub (input, 4)  + 0wx4bdecfa9, 0w11)
         val c' = f (c', d', a', b', sub (input, 7)  + 0wxf6bb4b60, 0w16)
         val b' = f (b', c', d', a', sub (input, 10) + 0wxbebfbc70, 0w23)

         val a' = f (a', b', c', d', sub (input, 13) + 0wx289b7ec6, 0w4)
         val d' = f (d', a', b', c', sub (input, 0)  + 0wxeaa127fa, 0w11)
         val c' = f (c', d', a', b', sub (input, 3)  + 0wxd4ef3085, 0w16)
         val b' = f (b', c', d', a', sub (input, 6)  + 0wx04881d05, 0w23)

         val a' = f (a', b', c', d', sub (input, 9)  + 0wxd9d4d039, 0w4)
         val d' = f (d', a', b', c', sub (input, 12) + 0wxe6db99e5, 0w11)
         val c' = f (c', d', a', b', sub (input, 15) + 0wx1fa27cf8, 0w16)
         val b' = f (b', c', d', a', sub (input, 2)  + 0wxc4ac5665, 0w23)
      in
         #[a+a', b+b', c+c', d+d']
      end

      fun round4 input v =
      let
         open Vector

         val f = (step F4)

         val a = sub (v, 0)
         val b = sub (v, 1)
         val c = sub (v, 2)
         val d = sub (v, 3)

         val a' = f (a,  b,  c,  d,  sub (input, 0)  + 0wxf4292244, 0w6)
         val d' = f (d,  a', b,  c,  sub (input, 7)  + 0wx432aff97, 0w10)
         val c' = f (c,  d', a', b,  sub (input, 14) + 0wxab9423a7, 0w15)
         val b' = f (b,  c', d', a', sub (input, 5)  + 0wxfc93a039, 0w21)

         val a' = f (a', b', c', d', sub (input, 12) + 0wx655b59c3, 0w6)
         val d' = f (d', a', b', c', sub (input, 3)  + 0wx8f0ccc92, 0w10)
         val c' = f (c', d', a', b', sub (input, 10) + 0wxffeff47d, 0w15)
         val b' = f (b', c', d', a', sub (input, 1)  + 0wx85845dd1, 0w21)

         val a' = f (a', b', c', d', sub (input, 8)  + 0wx6fa87e4f, 0w6)
         val d' = f (d', a', b', c', sub (input, 15) + 0wxfe2ce6e0, 0w10)
         val c' = f (c', d', a', b', sub (input, 6)  + 0wxa3014314, 0w15)
         val b' = f (b', c', d', a', sub (input, 13) + 0wx4e0811a1, 0w21)

         val a' = f (a', b', c', d', sub (input, 4)  + 0wxf7537e82, 0w6)
         val d' = f (d', a', b', c', sub (input, 11) + 0wxbd3af235, 0w10)
         val c' = f (c', d', a', b', sub (input, 2)  + 0wx2ad7d2bb, 0w15)
         val b' = f (b', c', d', a', sub (input, 9)  + 0wxeb86d391, 0w21)
      in
         #[a+a', b+b', c+c', d+d']
      end

      (* Pack the 64 bytes in the input into 16 eight-byte quantities. *)
      val words = Vector.map (fn w => Pack32Little.subVec (vec, w))
                             #[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11,
                               12, 13, 14, 15]
   in
      (* Compose up the roundX functions for this vector of the file. *)
      {size=size, digest=((round4 words o round3 words o
                           round2 words o round1 words) digest)}
   end

   (* Return the MD5 message digest of the provided file name. *)
   fun sum filename =
   let
      (* Reads 64 bytes out of the opened stream and applies the function f
       * to that vector.
       *)
      fun read (stream, {size, digest}, f) =
         if BinIO.endOfStream stream then
            ignore (print "\n")
         else
            let
               (* Given the message size and current vector, tack on the
                * padding and return a complete 64 byte vector suitable
                * for running the digest function on.
                *)
               fun final size vec =
               let
                  (* Padding consists of a 1, followed by enough 0s to
                   * bring the message length to 56-byte alignment.
                   *)
                  fun mk_pad len =
                     W8V.tabulate (len, (fn i => if i = 0 then 0w128 else 0w0))

                  (* Append the length of the message, low order word
                   * first.
                   *)
                  fun mk_size lw =
                  let
                     open Vector
                  in
                     W8V.fromList (foldr (fn (e, lst) =>
                                            (W8.fromLargeWord e)::lst)
                                         []
                                         (concat [unpack lw,
                                                  #[0w0, 0w0, 0w0, 0w0]]))
                  end

                  val pre = LW.mod (LW.fromInt (W8V.length vec), 0w56)
                  val size_vec = mk_size size
               in
                  W8V.concat [vec, mk_pad (LW.toInt (0w56-pre)), size_vec]
               end

               (* Print one word of the digest, padding as appropriate. *)
               val print_fn =
                  fn v => ( Vector.app (fn e => print (StringCvt.padLeft #"0" 2
                                                         (LW.toString e)))
                                       (unpack v) ;
                            print " " )

               val _ = ( Vector.app print_fn digest ; print "\n" )

               (* vec is a Word8Vector. *)
               val vec = BinIO.inputN (stream, 64)
               val len = LW.fromInt (W8V.length vec)
            in
               if len < 0w64 then
                  let
                     val size' = size+len
                     val {digest=digest', ...} =
                        f {size=size', digest=digest} (final size' vec)
                  in
                     Vector.app print_fn digest' ; print "\n"
                  end
               else
                  let
                     (* Update the digest state, accounting for new bytes. *)
                     val {size=size', digest=digest'} =
                        f {size=(size+len), digest=digest} vec
                  in
                     read (stream, {size=size', digest=digest'}, f)
                  end
            end

      val file = BinIO.openIn filename
      val state = init()
   in
      read (file, state, (transform)) before BinIO.closeIn file
   end
end
