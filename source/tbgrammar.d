module tbgrammar;

import pegged.grammar;

mixin(grammar(`
TINYBASIC:
    Program <- Line (NL* Line)+ EOI
    Line <- Line_id :WS? Statement?

    Statement < Const_stmt / Let_stmt / Print_stmt / If_stmt / Goto_stmt / Input_stmt / Gosub_stmt / Call_stmt / Return_stmt / Rem_stmt / Poke_stmt / For_stmt / Next_stmt / Dim_stmt / Charat_stmt / Data_stmt / Textat_stmt / Inc_stmt / Dec_stmt / Proc_stmt / Endproc_stmt / End_stmt / Sys_stmt
    Const_stmt <    "const" :WS? Var :WS? "=" :WS? Number
    Let_stmt <      ("let" / eps) :WS? Var :WS? "=" :WS? Expression
    Print_stmt <    "print" :WS? ExprList
    If_stmt <       "if" :WS? Expression :WS? Relop :WS? Expression :WS? "then" :WS? Statement :WS? ("else" :WS? Statement)?
    Goto_stmt <     "goto" :WS? (Label_ref / Unsigned)
    Input_stmt <    "input" :WS? VarList
    Gosub_stmt <    "gosub" :WS? (Label_ref / Unsigned)
    Call_stmt <     "call" :WS? (Label_ref / Unsigned) :WS? (:"(" :WS? ExprList :WS? :")")?
    Return_stmt <   "return"
    Poke_stmt <     "poke" :WS? Expression :WS? "," :WS? Expression
    End_stmt <      "end"
    Rem_stmt <      "rem" (!eol .)*
    For_stmt <      "for" :WS? Var :WS? "=" :WS? Expression "to" :WS? Expression
    Next_stmt <     "next" :WS? Var
    Dim_stmt <      "dim" :WS? Var
    Data_stmt <     "data" :WS? Varname Vartype "[]" :WS? "=" :WS? Datalist
    Charat_stmt <   "charat" :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? Expression
    Textat_stmt <   "textat" :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? (String / Expression)
    Inc_stmt <      "inc" :WS? Var
    Dec_stmt <      "dec" :WS? Var
    Proc_stmt <     "proc" :WS Label_ref :WS? (:"(" :WS? VarList :WS? :")")?
    Endproc_stmt <  "endproc"
    Sys_stmt <      "sys" :WS? Expression

    ExprList < (String / Expression) :WS? ("," :WS? (String / Expression) )*
    VarList < Var (:WS? "," :WS? Var)*
    Datalist < Number (:WS? "," :WS? Number)*
    Expression < ("+" / "-" / eps) :WS? Term :WS? (E_OP :WS? Term)*
    Term < Factor :WS? (T_OP :WS? Factor)*
    Factor < (Var / Number / Expression / Fn_call)
    Fn_call < Id "(" :WS? (ExprList / eps) :WS? ")"
    Var < Varname Vartype Subscript?

    T_OP < ("*" / "/")
    E_OP < ("+" / "-")

    Varname <- !Reserved "\\" ? [a-zA-Z_] [a-zA-Z_0-9]*
    Id <- [a-zA-Z_] [a-zA-Z_0-9]*
    Vartype <- ("%" / "#" /  eps)
    Subscript <- "[" Expression (:WS? "," :WS? Expression)? "]"

    Relop < "<" | "<=" | "=" | "<>" | ">" | ">="
    String < doublequote (!doublequote . / ^' ')* doublequote

    Unsigned   < [0-9]+
    Integer    < "-"? Unsigned
    Hexa       < "$" [0-9a-fA-F]+

    Number < (Integer / Hexa)

    Label < [a-zA-Z_] [a-zA-Z_0-9]* ":"
    Label_ref < [a-zA-Z_] [a-zA-Z_0-9]*

    Line_id < (Label / Unsigned / eps)

    Reserved < ("let" / "print" / "if" / "then" / "goto" / "input" / "gosub" / "return" / "end" / "rem" / "poke" / "peek" / "dim" / "data" / "inkey" / "rnd" / "inc" / "dec" / "proc" / "endproc")

    WS < space*
    EOI < !.

    NL <- ('\r' / '\n' / '\r\n')+
    Spacing <- :('\t')*
`));
