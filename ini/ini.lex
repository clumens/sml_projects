datatype lexresult = LBRACK | RBRACK | EQUAL | NAME of string | EOF

val lineno = ref 1

fun eof () = EOF

%%

%structure IniLex

%s VAL;

alpha    = [a-zA-Z];
idchars  = [a-zA-Z0-9_];
ws       = [\ \t];

%%

{ws}+ => (lex());

<INITIAL> {alpha}{idchars}* => (NAME(yytext));

<INITIAL> "["     => (LBRACK);
<INITIAL> "]"     => (RBRACK);
<INITIAL> "="     => (YYBEGIN VAL ; EQUAL);
<INITIAL> "\n"    => (lineno := !lineno + 1; lex());

<VAL> "\n"        => (YYBEGIN INITIAL ; lex());
<VAL> .+          => (NAME(yytext));

.                 => (print ("bad char at line " ^ Int.toString (!lineno) ^
                             ": " ^ yytext ^ "\n");
                      lex());
