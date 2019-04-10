module tbgrammar;

import pegged.grammar;

mixin(grammar(`
XCBASIC:
    Program <- Line (NL* Line)+ EOI
    Line <- Line_id :WS? Statements?
    Statements < Statement :WS? (":" :WS? Statement :WS?)*

    Statement < Const_stmt / Let_stmt / Print_stmt / If_stmt / Goto_stmt / Input_stmt / Gosub_stmt / Call_stmt / Return_stmt / Rem_stmt / Poke_stmt / For_stmt / Next_stmt / Dim_stmt / Charat_stmt / Data_stmt / Textat_stmt / Inc_stmt / Dec_stmt / Proc_stmt / Endproc_stmt / End_stmt / Sys_stmt / Load_stmt / Save_stmt
    Const_stmt <    "const" :WS? Var :WS? "=" :WS? Number
    Let_stmt <      ("let" / eps) :WS? Var :WS? "=" :WS? Expression
    Print_stmt <    "print" :WS? ExprList
    If_stmt <       "if" :WS? Relation :WS? (Logop :WS? Relation)? :WS? "then" :WS? Statements :WS? ("else" :WS? Statements)?
    Goto_stmt <     "goto" :WS? (Label_ref / Unsigned)
    Input_stmt <    "input" :WS? VarList
    Gosub_stmt <    "gosub" :WS? (Label_ref / Unsigned)
    Call_stmt <     "call" :WS? (Label_ref / Unsigned) :WS? (:"(" :WS? ExprList :WS? :")")?
    Return_stmt <   "return"
    Poke_stmt <     "poke" :WS? Expression :WS? "," :WS? Expression
    End_stmt <      "end"
    Rem_stmt <      "rem" (!eol .)*
    For_stmt <      "for" :WS? Var :WS? "=" :WS? Expression :WS? "to" :WS? Expression
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
    Load_stmt <     "load" :WS? String :WS? "," :WS? Expression (:WS? "," :WS? Expression)?
    Save_stmt <     "save" :WS? String :WS? "," :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? Expression

    Relation < Expression :WS? Relop :WS? Expression
    ExprList < (String / Expression) :WS? ("," :WS? (String / Expression) )*
    VarList < Var (:WS? "," :WS? Var)*
    Datalist < Number (:WS? "," :WS? Number :WS?)*
    Expression < Simplexp (:WS? BW_OP :WS? Simplexp :WS?)*
    Simplexp < Term (:WS? E_OP :WS? Term :WS?)*
    Term < Factor (:WS? T_OP :WS? Factor :WS?)*
    Factor < ( Var / Number / Parenthesis / Expression / Fn_call / Address )
    Fn_call < Id "(" :WS? (ExprList / eps) :WS? ")"
    Var < Varname Vartype Subscript?
    Parenthesis < "(" :WS? Expression :WS? ")"

    T_OP < ("*" / "/")
    E_OP < ("+" / "-")
    BW_OP < ("&" / "|" / "^")

    Varname <- !Reserved "\\" ? [a-zA-Z_] [a-zA-Z_0-9]*
    Address < "@" Varname
    Id <- [a-zA-Z_] [a-zA-Z_0-9]*
    Vartype <- ("%" / "#" /  eps)
    Subscript <- "[" Expression (:WS? "," :WS? Expression)? "]"

    Logop < "and" | "or"
    Relop < "<" | "<=" | "=" | "<>" | ">" | ">="
    String < doublequote (!doublequote . / ^' ')* doublequote

    Unsigned   < [0-9]+
    Integer    < "-"? Unsigned
    Hexa       < "$" [0-9a-fA-F]+

    Number < (Integer / Hexa)

    Label < [a-zA-Z_] [a-zA-Z_0-9]* ":"
    Label_ref < [a-zA-Z_] [a-zA-Z_0-9]*

    Line_id < (Label / Unsigned / eps)

    Reserved < ("const" / "let" / "print" / "if" / "then" / "goto" / "input" / "gosub" / "return" / "call" / "end" / "rem" / "poke" / "peek" / "for" / "to" / "next" / "dim" / "data" / "charat" / "textat" / "inkey" / "rnd" / "inc" / "dec" / "proc" / "endproc" / "sys" / "usr" / "and" / "or" / "load" / "save" / "ferr")

    WS < (space / "~" ('\r' / '\n' / '\r\n')+ )*
    EOI < !.

    NL <- !"~" ('\r' / '\n' / '\r\n')+
    Spacing <- :('\t')*
`));
