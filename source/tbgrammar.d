module tbgrammar;

import pegged.grammar;

mixin(grammar(`
XCBASIC:
    Program <- Line (NL* Line)+ EOI
    Line <- Line_id :WS? Statements?
    Statements < Statement :WS? (":" :WS? Statement :WS?)*

    Statement < Const_stmt / Let_stmt / Print_stmt / If_stmt / Goto_stmt / Input_stmt / Gosub_stmt / Call_stmt / Return_stmt /
                Rem_stmt / Poke_stmt / For_stmt / Next_stmt / Dim_stmt / Charat_stmt / Data_stmt / Textat_stmt / Incbin_stmt /
                Include_stmt / Inc_stmt / Dec_stmt / Proc_stmt / Endproc_stmt /  Sys_stmt / Load_stmt / Save_stmt /
                Origin_stmt / Asm_stmt / Doke_stmt / Strcpy_stmt / Strncpy_stmt / Curpos_stmt / On_stmt / Wait_stmt / Watch_stmt /
                Pragma_stmt / Memset_stmt / Memcpy_stmt / Memshift_stmt / While_stmt / Endwhile_stmt /
                If_sa_stmt / Else_stmt / Endif_stmt / End_stmt / Repeat_stmt / Until_stmt
    Const_stmt <    "const"i :WS? Var :WS? "=" :WS? Number
    Let_stmt <      ("let"i / eps) :WS? Var :WS? "=" :WS? Expression
    Print_stmt <    "print"i :WS? ExprList
    If_stmt <       "if"i :WS? Condition :WS? "then"i :WS? Statements :WS? ("else"i :WS? Statements)?
    If_sa_stmt <    "if"i :WS? Condition :WS? "then"i
    Else_stmt <     "else"i
    Endif_stmt <    "endif"i
    Goto_stmt <     "goto"i :WS? (Label_ref / Unsigned)
    Input_stmt <    "input"i :WS? Var :WS? "," :WS? Expression :WS? ("," :WS? String)?
    Gosub_stmt <    "gosub"i :WS? (Label_ref / Unsigned)
    Call_stmt <     "call"i :WS? (Label_ref / Unsigned) :WS? (:"(" :WS? ExprList :WS? :")")?
    Return_stmt <   "return"i
    Poke_stmt <     "poke"i :WS? Expression :WS? "," :WS? Expression
    Doke_stmt <     "doke"i :WS? Expression :WS? "," :WS? Expression
    While_stmt  <   "while"i :WS? Condition
    Endwhile_stmt < "endwhile"i
    End_stmt <      "end"i
    Repeat_stmt <   "repeat"i
    Until_stmt <    "until"i :WS? Condition
    Rem_stmt <      (";" / "'" / "rem"i) (!eol .)*
    For_stmt <      "for"i :WS? Var :WS? "=" :WS    ? Expression :WS? "to"i :WS? Expression
    Next_stmt <     "next"i :WS? Var
    Dim_stmt <      "dim"i :WS? Var (:WS "fast"i)?
    Data_stmt <     "data"i :WS? Varname Vartype "[]" :WS? "=" :WS? (Datalist / Incbin_stmt)
    Charat_stmt <   "charat"i :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? Expression
    Textat_stmt <   "textat"i :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? (String / Expression)
    Asm_stmt <      "asm"i :WS? String
    Incbin_stmt <   "incbin"i :WS? String
    Include_stmt <  "include"i :WS? String
    Inc_stmt <      "inc"i :WS? Var
    Dec_stmt <      "dec"i :WS? Var
    Proc_stmt <     "proc"i :WS Label_ref :WS? (:"(" :WS? VarList :WS? :")")?
    Endproc_stmt <  "endproc"i
    Sys_stmt <      "sys"i :WS? Expression
    Load_stmt <     "load"i :WS? String :WS? "," :WS? Expression (:WS? "," :WS? Expression)?
    Save_stmt <     "save"i :WS? String :WS? "," :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? Expression
    Origin_stmt <   "origin"i :WS? Number
    Strcpy_stmt <   "strcpy"i :WS? Expression :WS? "," :WS? Expression
    Strncpy_stmt <  "strncpy"i :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? Expression
    Curpos_stmt <   "curpos"i :WS? Expression :WS? "," :WS? Expression
    On_stmt <       "on"i :WS? Expression :WS? Branch_type :WS? Label_ref (:WS? "," :WS? Label_ref)*
    Wait_stmt <     "wait"i :WS? Expression :WS? "," :WS? Expression (:WS? "," :WS? Expression)?
    Watch_stmt <    "watch"i :WS? Expression :WS? "," :WS? Expression
    Pragma_stmt <   "pragma"i :WS? Id :WS? "=" :WS? Number
    Memset_stmt <   "memset"i :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? Expression
    Memcpy_stmt <   "memcpy"i :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? Expression
    Memshift_stmt < "memshift"i :WS? Expression :WS? "," :WS? Expression :WS? "," :WS? Expression

    Branch_type < "goto"i / "gosub"i
    Relation < Expression :WS? Relop :WS? Expression
    Condition < Relation :WS? (Logop :WS? Relation)?
    ExprList < Expression :WS? ("," :WS? Expression)*
    VarList < Var (:WS? "," :WS? Var)*
    Datalist < (Number / String) (:WS? "," :WS? (Number / String) :WS?)*

    Expression < Simplexp (:WS? BW_OP :WS? Simplexp :WS?)*
    Simplexp < Term (:WS? E_OP :WS? Term :WS?)*
    Term < Factor (:WS? T_OP :WS? Factor :WS?)*
    Factor < (Var / Number / Parenthesis / String / Expression / Fn_call / Address)
    Fn_call < Id Vartype  "(" :WS? (ExprList / eps) :WS? ")"

    Var < Varname Vartype Subscript?
    Parenthesis < :"(" :WS? Expression :WS? :")"

    T_OP < ("*" / "/")
    E_OP < ("+" / "-")
    BW_OP < ("&" / "|" / "^")

    Varname <- !Reserved "\\" ? [a-zA-Z_] [a-zA-Z_0-9]*
    Address < "@" Varname Vartype Subscript?
    Id <- [a-zA-Z_] [a-zA-Z_0-9]*
    Vartype <- ("%" / "#" / "!" / "$" / eps)
    Subscript <- "[" Expression (:WS? "," :WS? Expression)? "]"
    Logop < "and" | "or"
    Relop < "<" | "<=" | "=" | "<>" | ">" | ">="
    String < doublequote (!doublequote . / ^' ')* doublequote

    Unsigned   < [0-9]+
    Integer    < "-"? Unsigned
    Hexa       < "$" [0-9a-fA-F]+
    Binary     < "%" ("0" / "1")+
    Scientific < Floating ('e' / 'E' ) Integer
    Floating   < "-"? Unsigned "." Unsigned
    Charlit    < ("'{" [a-zA-Z_0-9]+ "}'") / ("'" . "'")

    Number < (Scientific / Floating / Integer / Hexa / Binary / Charlit)

    Label < [a-zA-Z_] [a-zA-Z_0-9]* ":"
    Label_ref < [a-zA-Z_] [a-zA-Z_0-9]*

    Line_id < (Label / Unsigned / eps)

    Reserved < ("const"i / "let"i / "print"i / "if"i / "then"i / "goto"i / "input"i / "gosub"i / "return"i / "call"i /
                 "end"i / "rem"i / "poke"i / "peek"i / "for"i / "to"i / "next"i / "dim"i / "data"i / "charat"i / "textat"i /
                 "inkey"i / "rnd"i / "incbin"i / "inc"i / "dec"i / "proc"i / "endproc"i / "sys"i / "usr"i / "and"i / "origin"i /
                  "or"i / "load"i / "save"i / "ferr"i / "deek"i / "doke"i /
                 "abs"i / "cast"i / "sin"i / "cos"i / "tan"i / "atn"i / "asm"i / "strcpy"i / "strncpy"i / "strlen"i / "strcmp"i / "curpos"i /
                 "strpos"i / "val"i / "sqr"i / "sgn"i / "wait"i / "watch"i / "pragma"i / "memset"i / "memcpy"i / "memshift"i /
                 "while"i / "endwhile"i / "repeat"i / "until"i / "lshift"i / "rshift"i)
    WS < (space / "~" ('\r' / '\n' / '\r\n')+ )*
    EOI < !.

    NL <- !"~" ('\r' / '\n' / '\r\n')+
    Spacing <- :('\t')*
`));
