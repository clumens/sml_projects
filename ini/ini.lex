(* $Id: ini.lex,v 1.3 2004/08/07 05:41:47 chris Exp $ *)

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
structure Tokens = Tokens

type pos = int
type svalue = Tokens.svalue
type ('a,'b) token = ('a,'b) Tokens.token
type lexresult= (svalue,pos) token

val lineno = ref 1

fun eof () = Tokens.EOF(!lineno, !lineno)

%%

%header (functor IniLexFun(structure Tokens: IniParser_TOKENS));

%s VAL;

alpha    = [a-zA-Z];
idchars  = [a-zA-Z0-9_];
ws       = [\ \t];

%%

{ws}+ => (lex());

<INITIAL> {alpha}{idchars}* => (Tokens.NAME(yytext, !lineno, !lineno));

<INITIAL> "["     => (Tokens.LBRACK(!lineno, !lineno));
<INITIAL> "]"     => (Tokens.RBRACK(!lineno, !lineno));
<INITIAL> "="     => (YYBEGIN VAL ; Tokens.EQUAL(!lineno, !lineno));
<INITIAL> "\n"    => (lineno := !lineno + 1; lex());

<VAL> "\n"        => (lineno := !lineno + 1; YYBEGIN INITIAL ; lex());
<VAL> .+          => (Tokens.NAME(yytext, !lineno, !lineno));

.                 => (print ("bad char at line " ^ Int.toString (!lineno) ^
                             ": " ^ yytext ^ "\n");
                      lex());
