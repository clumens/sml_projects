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

<VAL> "\n"        => (YYBEGIN INITIAL ; lex());
<VAL> .+          => (Tokens.NAME(yytext, !lineno, !lineno));

.                 => (print ("bad char at line " ^ Int.toString (!lineno) ^
                             ": " ^ yytext ^ "\n");
                      lex());
