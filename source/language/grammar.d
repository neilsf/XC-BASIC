module language.grammar;

import pegged.grammar;

/** Left-recursive cycles:
Expression <- Simplexp <- Term <- Factor
*/

/** Rules that stop left-recursive cycles, followed by rules for which
 *  memoization is blocked during recursion:
Expression: Expression, Simplexp, Term, Factor
*/

struct GenericXCBASIC(TParseTree)
{
    import std.functional : toDelegate;
    import pegged.dynamic.grammar;
    static import pegged.peg;
    struct XCBASIC
    {
    enum name = "XCBASIC";
    static ParseTree delegate(ParseTree)[string] before;
    static ParseTree delegate(ParseTree)[string] after;
    static ParseTree delegate(ParseTree)[string] rules;
    import std.typecons:Tuple, tuple;
    static TParseTree[Tuple!(string, size_t)] memo;
    import std.algorithm: canFind, countUntil, remove;
    static size_t[] blockMemoAtPos;
    static this()
    {
        rules["Program"] = toDelegate(&Program);
        rules["Line"] = toDelegate(&Line);
        rules["Statements"] = toDelegate(&Statements);
        rules["Statement"] = toDelegate(&Statement);
        rules["Const_stmt"] = toDelegate(&Const_stmt);
        rules["Let_stmt"] = toDelegate(&Let_stmt);
        rules["Print_stmt"] = toDelegate(&Print_stmt);
        rules["If_stmt"] = toDelegate(&If_stmt);
        rules["If_sa_stmt"] = toDelegate(&If_sa_stmt);
        rules["Else_stmt"] = toDelegate(&Else_stmt);
        rules["Endif_stmt"] = toDelegate(&Endif_stmt);
        rules["Goto_stmt"] = toDelegate(&Goto_stmt);
        rules["Input_stmt"] = toDelegate(&Input_stmt);
        rules["Gosub_stmt"] = toDelegate(&Gosub_stmt);
        rules["Call_stmt"] = toDelegate(&Call_stmt);
        rules["Return_stmt"] = toDelegate(&Return_stmt);
        rules["Return_fn_stmt"] = toDelegate(&Return_fn_stmt);
        rules["Poke_stmt"] = toDelegate(&Poke_stmt);
        rules["Doke_stmt"] = toDelegate(&Doke_stmt);
        rules["While_stmt"] = toDelegate(&While_stmt);
        rules["Endwhile_stmt"] = toDelegate(&Endwhile_stmt);
        rules["Repeat_stmt"] = toDelegate(&Repeat_stmt);
        rules["Until_stmt"] = toDelegate(&Until_stmt);
        rules["Rem_stmt"] = toDelegate(&Rem_stmt);
        rules["For_stmt"] = toDelegate(&For_stmt);
        rules["Next_stmt"] = toDelegate(&Next_stmt);
        rules["Dim_stmt"] = toDelegate(&Dim_stmt);
        rules["Data_stmt"] = toDelegate(&Data_stmt);
        rules["Charat_stmt"] = toDelegate(&Charat_stmt);
        rules["Textat_stmt"] = toDelegate(&Textat_stmt);
        rules["Asm_stmt"] = toDelegate(&Asm_stmt);
        rules["Incbin_stmt"] = toDelegate(&Incbin_stmt);
        rules["Include_stmt"] = toDelegate(&Include_stmt);
        rules["Inc_stmt"] = toDelegate(&Inc_stmt);
        rules["Dec_stmt"] = toDelegate(&Dec_stmt);
        rules["Proc_stmt"] = toDelegate(&Proc_stmt);
        rules["Fun_stmt"] = toDelegate(&Fun_stmt);
        rules["Endproc_stmt"] = toDelegate(&Endproc_stmt);
        rules["Endfun_stmt"] = toDelegate(&Endfun_stmt);
        rules["Sys_stmt"] = toDelegate(&Sys_stmt);
        rules["Load_stmt"] = toDelegate(&Load_stmt);
        rules["Save_stmt"] = toDelegate(&Save_stmt);
        rules["Origin_stmt"] = toDelegate(&Origin_stmt);
        rules["Strcpy_stmt"] = toDelegate(&Strcpy_stmt);
        rules["Strncpy_stmt"] = toDelegate(&Strncpy_stmt);
        rules["Curpos_stmt"] = toDelegate(&Curpos_stmt);
        rules["On_stmt"] = toDelegate(&On_stmt);
        rules["Wait_stmt"] = toDelegate(&Wait_stmt);
        rules["Watch_stmt"] = toDelegate(&Watch_stmt);
        rules["Pragma_stmt"] = toDelegate(&Pragma_stmt);
        rules["Memset_stmt"] = toDelegate(&Memset_stmt);
        rules["Memcpy_stmt"] = toDelegate(&Memcpy_stmt);
        rules["Memshift_stmt"] = toDelegate(&Memshift_stmt);
        rules["Disableirq_stmt"] = toDelegate(&Disableirq_stmt);
        rules["Enableirq_stmt"] = toDelegate(&Enableirq_stmt);
        rules["End_stmt"] = toDelegate(&End_stmt);
        rules["Userdef_cmd"] = toDelegate(&Userdef_cmd);
        rules["Branch_type"] = toDelegate(&Branch_type);
        rules["Relation"] = toDelegate(&Relation);
        rules["Condition"] = toDelegate(&Condition);
        rules["ExprList"] = toDelegate(&ExprList);
        rules["VarList"] = toDelegate(&VarList);
        rules["Datalist"] = toDelegate(&Datalist);
        rules["Expression"] = toDelegate(&Expression);
        rules["Simplexp"] = toDelegate(&Simplexp);
        rules["Term"] = toDelegate(&Term);
        rules["Factor"] = toDelegate(&Factor);
        rules["Fn_call"] = toDelegate(&Fn_call);
        rules["Var"] = toDelegate(&Var);
        rules["Parenthesis"] = toDelegate(&Parenthesis);
        rules["T_OP"] = toDelegate(&T_OP);
        rules["E_OP"] = toDelegate(&E_OP);
        rules["BW_OP"] = toDelegate(&BW_OP);
        rules["Varname"] = toDelegate(&Varname);
        rules["Address"] = toDelegate(&Address);
        rules["Id"] = toDelegate(&Id);
        rules["Vartype"] = toDelegate(&Vartype);
        rules["Subscript"] = toDelegate(&Subscript);
        rules["Logop"] = toDelegate(&Logop);
        rules["Relop"] = toDelegate(&Relop);
        rules["String"] = toDelegate(&String);
        rules["Unsigned"] = toDelegate(&Unsigned);
        rules["Integer"] = toDelegate(&Integer);
        rules["Hexa"] = toDelegate(&Hexa);
        rules["Binary"] = toDelegate(&Binary);
        rules["Scientific"] = toDelegate(&Scientific);
        rules["Floating"] = toDelegate(&Floating);
        rules["Charlit"] = toDelegate(&Charlit);
        rules["Number"] = toDelegate(&Number);
        rules["Label"] = toDelegate(&Label);
        rules["Label_ref"] = toDelegate(&Label_ref);
        rules["Line_id"] = toDelegate(&Line_id);
        rules["Reserved"] = toDelegate(&Reserved);
        rules["WS"] = toDelegate(&WS);
        rules["EOI"] = toDelegate(&EOI);
        rules["NL"] = toDelegate(&NL);
        rules["Spacing"] = toDelegate(&Spacing);
    }

    template hooked(alias r, string name)
    {
        static ParseTree hooked(ParseTree p)
        {
            ParseTree result;

            if (name in before)
            {
                result = before[name](p);
                if (result.successful)
                    return result;
            }

            result = r(p);
            if (result.successful || name !in after)
                return result;

            result = after[name](p);
            return result;
        }

        static ParseTree hooked(string input)
        {
            return hooked!(r, name)(ParseTree("",false,[],input));
        }
    }

    static void addRuleBefore(string parentRule, string ruleSyntax)
    {
        // enum name is the current grammar name
        DynamicGrammar dg = pegged.dynamic.grammar.grammar(name ~ ": " ~ ruleSyntax, rules);
        foreach(ruleName,rule; dg.rules)
            if (ruleName != "Spacing") // Keep the local Spacing rule, do not overwrite it
                rules[ruleName] = rule;
        before[parentRule] = rules[dg.startingRule];
    }

    static void addRuleAfter(string parentRule, string ruleSyntax)
    {
        // enum name is the current grammar named
        DynamicGrammar dg = pegged.dynamic.grammar.grammar(name ~ ": " ~ ruleSyntax, rules);
        foreach(name,rule; dg.rules)
        {
            if (name != "Spacing")
                rules[name] = rule;
        }
        after[parentRule] = rules[dg.startingRule];
    }

    static bool isRule(string s)
    {
		import std.algorithm : startsWith;
        return s.startsWith("XCBASIC.");
    }
    mixin decimateTree;

    static TParseTree Program(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(Line, pegged.peg.oneOrMore!(pegged.peg.and!(pegged.peg.zeroOrMore!(NL), Line)), EOI), "XCBASIC.Program")(p);
        }
        else
        {
            if (auto m = tuple(`Program`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(Line, pegged.peg.oneOrMore!(pegged.peg.and!(pegged.peg.zeroOrMore!(NL), Line)), EOI), "XCBASIC.Program"), "Program")(p);
                memo[tuple(`Program`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Program(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(Line, pegged.peg.oneOrMore!(pegged.peg.and!(pegged.peg.zeroOrMore!(NL), Line)), EOI), "XCBASIC.Program")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(Line, pegged.peg.oneOrMore!(pegged.peg.and!(pegged.peg.zeroOrMore!(NL), Line)), EOI), "XCBASIC.Program"), "Program")(TParseTree("", false,[], s));
        }
    }
    static string Program(GetName g)
    {
        return "XCBASIC.Program";
    }

    static TParseTree Line(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(WS)), Line_id, pegged.peg.discard!(pegged.peg.option!(WS)), pegged.peg.option!(Statements)), "XCBASIC.Line")(p);
        }
        else
        {
            if (auto m = tuple(`Line`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(WS)), Line_id, pegged.peg.discard!(pegged.peg.option!(WS)), pegged.peg.option!(Statements)), "XCBASIC.Line"), "Line")(p);
                memo[tuple(`Line`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Line(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(WS)), Line_id, pegged.peg.discard!(pegged.peg.option!(WS)), pegged.peg.option!(Statements)), "XCBASIC.Line")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(WS)), Line_id, pegged.peg.discard!(pegged.peg.option!(WS)), pegged.peg.option!(Statements)), "XCBASIC.Line"), "Line")(TParseTree("", false,[], s));
        }
    }
    static string Line(GetName g)
    {
        return "XCBASIC.Line";
    }

    static TParseTree Statements(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Statement, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(":"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statement, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Statements")(p);
        }
        else
        {
            if (auto m = tuple(`Statements`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Statement, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(":"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statement, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Statements"), "Statements")(p);
                memo[tuple(`Statements`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Statements(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Statement, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(":"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statement, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Statements")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Statement, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(":"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statement, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Statements"), "Statements")(TParseTree("", false,[], s));
        }
    }
    static string Statements(GetName g)
    {
        return "XCBASIC.Statements";
    }

    static TParseTree Statement(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Const_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Let_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Print_stmt, Spacing), pegged.peg.wrapAround!(Spacing, If_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Goto_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Input_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Gosub_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Call_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Rem_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Poke_stmt, Spacing), pegged.peg.wrapAround!(Spacing, For_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Next_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Dim_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Charat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Data_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Textat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Incbin_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Include_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Inc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Dec_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Proc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endproc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Sys_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Load_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Save_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Origin_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Asm_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Doke_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Strcpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Strncpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Curpos_stmt, Spacing), pegged.peg.wrapAround!(Spacing, On_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Wait_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Watch_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Pragma_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memset_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memcpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memshift_stmt, Spacing), pegged.peg.wrapAround!(Spacing, While_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endwhile_stmt, Spacing), pegged.peg.wrapAround!(Spacing, If_sa_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Else_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endif_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Repeat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Until_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Disableirq_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Enableirq_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Fun_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endfun_stmt, Spacing), pegged.peg.wrapAround!(Spacing, End_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Return_fn_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Return_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Userdef_cmd, Spacing)), "XCBASIC.Statement")(p);
        }
        else
        {
            if (auto m = tuple(`Statement`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Const_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Let_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Print_stmt, Spacing), pegged.peg.wrapAround!(Spacing, If_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Goto_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Input_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Gosub_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Call_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Rem_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Poke_stmt, Spacing), pegged.peg.wrapAround!(Spacing, For_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Next_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Dim_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Charat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Data_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Textat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Incbin_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Include_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Inc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Dec_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Proc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endproc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Sys_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Load_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Save_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Origin_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Asm_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Doke_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Strcpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Strncpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Curpos_stmt, Spacing), pegged.peg.wrapAround!(Spacing, On_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Wait_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Watch_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Pragma_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memset_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memcpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memshift_stmt, Spacing), pegged.peg.wrapAround!(Spacing, While_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endwhile_stmt, Spacing), pegged.peg.wrapAround!(Spacing, If_sa_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Else_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endif_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Repeat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Until_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Disableirq_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Enableirq_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Fun_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endfun_stmt, Spacing), pegged.peg.wrapAround!(Spacing, End_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Return_fn_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Return_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Userdef_cmd, Spacing)), "XCBASIC.Statement"), "Statement")(p);
                memo[tuple(`Statement`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Statement(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Const_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Let_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Print_stmt, Spacing), pegged.peg.wrapAround!(Spacing, If_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Goto_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Input_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Gosub_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Call_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Rem_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Poke_stmt, Spacing), pegged.peg.wrapAround!(Spacing, For_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Next_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Dim_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Charat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Data_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Textat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Incbin_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Include_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Inc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Dec_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Proc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endproc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Sys_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Load_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Save_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Origin_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Asm_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Doke_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Strcpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Strncpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Curpos_stmt, Spacing), pegged.peg.wrapAround!(Spacing, On_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Wait_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Watch_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Pragma_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memset_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memcpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memshift_stmt, Spacing), pegged.peg.wrapAround!(Spacing, While_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endwhile_stmt, Spacing), pegged.peg.wrapAround!(Spacing, If_sa_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Else_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endif_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Repeat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Until_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Disableirq_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Enableirq_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Fun_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endfun_stmt, Spacing), pegged.peg.wrapAround!(Spacing, End_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Return_fn_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Return_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Userdef_cmd, Spacing)), "XCBASIC.Statement")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Const_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Let_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Print_stmt, Spacing), pegged.peg.wrapAround!(Spacing, If_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Goto_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Input_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Gosub_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Call_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Rem_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Poke_stmt, Spacing), pegged.peg.wrapAround!(Spacing, For_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Next_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Dim_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Charat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Data_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Textat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Incbin_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Include_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Inc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Dec_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Proc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endproc_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Sys_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Load_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Save_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Origin_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Asm_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Doke_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Strcpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Strncpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Curpos_stmt, Spacing), pegged.peg.wrapAround!(Spacing, On_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Wait_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Watch_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Pragma_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memset_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memcpy_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Memshift_stmt, Spacing), pegged.peg.wrapAround!(Spacing, While_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endwhile_stmt, Spacing), pegged.peg.wrapAround!(Spacing, If_sa_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Else_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endif_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Repeat_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Until_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Disableirq_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Enableirq_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Fun_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Endfun_stmt, Spacing), pegged.peg.wrapAround!(Spacing, End_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Return_fn_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Return_stmt, Spacing), pegged.peg.wrapAround!(Spacing, Userdef_cmd, Spacing)), "XCBASIC.Statement"), "Statement")(TParseTree("", false,[], s));
        }
    }
    static string Statement(GetName g)
    {
        return "XCBASIC.Statement";
    }

    static TParseTree Const_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("const"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Const_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Const_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("const"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Const_stmt"), "Const_stmt")(p);
                memo[tuple(`Const_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Const_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("const"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Const_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("const"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Const_stmt"), "Const_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Const_stmt(GetName g)
    {
        return "XCBASIC.Const_stmt";
    }

    static TParseTree Let_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("let"), Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Let_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Let_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("let"), Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Let_stmt"), "Let_stmt")(p);
                memo[tuple(`Let_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Let_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("let"), Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Let_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("let"), Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Let_stmt"), "Let_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Let_stmt(GetName g)
    {
        return "XCBASIC.Let_stmt";
    }

    static TParseTree Print_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("print"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(";"), Spacing))), "XCBASIC.Print_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Print_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("print"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(";"), Spacing))), "XCBASIC.Print_stmt"), "Print_stmt")(p);
                memo[tuple(`Print_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Print_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("print"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(";"), Spacing))), "XCBASIC.Print_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("print"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(";"), Spacing))), "XCBASIC.Print_stmt"), "Print_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Print_stmt(GetName g)
    {
        return "XCBASIC.Print_stmt";
    }

    static TParseTree If_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statements, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("else"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statements, Spacing)), Spacing))), "XCBASIC.If_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`If_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statements, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("else"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statements, Spacing)), Spacing))), "XCBASIC.If_stmt"), "If_stmt")(p);
                memo[tuple(`If_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree If_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statements, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("else"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statements, Spacing)), Spacing))), "XCBASIC.If_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statements, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("else"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Statements, Spacing)), Spacing))), "XCBASIC.If_stmt"), "If_stmt")(TParseTree("", false,[], s));
        }
    }
    static string If_stmt(GetName g)
    {
        return "XCBASIC.If_stmt";
    }

    static TParseTree If_sa_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing)), "XCBASIC.If_sa_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`If_sa_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing)), "XCBASIC.If_sa_stmt"), "If_sa_stmt")(p);
                memo[tuple(`If_sa_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree If_sa_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing)), "XCBASIC.If_sa_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing)), "XCBASIC.If_sa_stmt"), "If_sa_stmt")(TParseTree("", false,[], s));
        }
    }
    static string If_sa_stmt(GetName g)
    {
        return "XCBASIC.If_sa_stmt";
    }

    static TParseTree Else_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("else"), Spacing), "XCBASIC.Else_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Else_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("else"), Spacing), "XCBASIC.Else_stmt"), "Else_stmt")(p);
                memo[tuple(`Else_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Else_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("else"), Spacing), "XCBASIC.Else_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("else"), Spacing), "XCBASIC.Else_stmt"), "Else_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Else_stmt(GetName g)
    {
        return "XCBASIC.Else_stmt";
    }

    static TParseTree Endif_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endif"), Spacing), "XCBASIC.Endif_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Endif_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endif"), Spacing), "XCBASIC.Endif_stmt"), "Endif_stmt")(p);
                memo[tuple(`Endif_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Endif_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endif"), Spacing), "XCBASIC.Endif_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endif"), Spacing), "XCBASIC.Endif_stmt"), "Endif_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Endif_stmt(GetName g)
    {
        return "XCBASIC.Endif_stmt";
    }

    static TParseTree Goto_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing)), "XCBASIC.Goto_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Goto_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing)), "XCBASIC.Goto_stmt"), "Goto_stmt")(p);
                memo[tuple(`Goto_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Goto_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing)), "XCBASIC.Goto_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing)), "XCBASIC.Goto_stmt"), "Goto_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Goto_stmt(GetName g)
    {
        return "XCBASIC.Goto_stmt";
    }

    static TParseTree Input_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("input"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing))), "XCBASIC.Input_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Input_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("input"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing))), "XCBASIC.Input_stmt"), "Input_stmt")(p);
                memo[tuple(`Input_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Input_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("input"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing))), "XCBASIC.Input_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("input"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing))), "XCBASIC.Input_stmt"), "Input_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Input_stmt(GetName g)
    {
        return "XCBASIC.Input_stmt";
    }

    static TParseTree Gosub_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing)), "XCBASIC.Gosub_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Gosub_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing)), "XCBASIC.Gosub_stmt"), "Gosub_stmt")(p);
                memo[tuple(`Gosub_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Gosub_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing)), "XCBASIC.Gosub_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing)), "XCBASIC.Gosub_stmt"), "Gosub_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Gosub_stmt(GetName g)
    {
        return "XCBASIC.Gosub_stmt";
    }

    static TParseTree Call_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("call"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), Spacing))), "XCBASIC.Call_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Call_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("call"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), Spacing))), "XCBASIC.Call_stmt"), "Call_stmt")(p);
                memo[tuple(`Call_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Call_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("call"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), Spacing))), "XCBASIC.Call_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("call"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), Spacing))), "XCBASIC.Call_stmt"), "Call_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Call_stmt(GetName g)
    {
        return "XCBASIC.Call_stmt";
    }

    static TParseTree Return_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), "XCBASIC.Return_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Return_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), "XCBASIC.Return_stmt"), "Return_stmt")(p);
                memo[tuple(`Return_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Return_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), "XCBASIC.Return_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), "XCBASIC.Return_stmt"), "Return_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Return_stmt(GetName g)
    {
        return "XCBASIC.Return_stmt";
    }

    static TParseTree Return_fn_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Return_fn_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Return_fn_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Return_fn_stmt"), "Return_fn_stmt")(p);
                memo[tuple(`Return_fn_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Return_fn_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Return_fn_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Return_fn_stmt"), "Return_fn_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Return_fn_stmt(GetName g)
    {
        return "XCBASIC.Return_fn_stmt";
    }

    static TParseTree Poke_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("poke"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Poke_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Poke_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("poke"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Poke_stmt"), "Poke_stmt")(p);
                memo[tuple(`Poke_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Poke_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("poke"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Poke_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("poke"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Poke_stmt"), "Poke_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Poke_stmt(GetName g)
    {
        return "XCBASIC.Poke_stmt";
    }

    static TParseTree Doke_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("doke"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Doke_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Doke_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("doke"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Doke_stmt"), "Doke_stmt")(p);
                memo[tuple(`Doke_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Doke_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("doke"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Doke_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("doke"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Doke_stmt"), "Doke_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Doke_stmt(GetName g)
    {
        return "XCBASIC.Doke_stmt";
    }

    static TParseTree While_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("while"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "XCBASIC.While_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`While_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("while"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "XCBASIC.While_stmt"), "While_stmt")(p);
                memo[tuple(`While_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree While_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("while"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "XCBASIC.While_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("while"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "XCBASIC.While_stmt"), "While_stmt")(TParseTree("", false,[], s));
        }
    }
    static string While_stmt(GetName g)
    {
        return "XCBASIC.While_stmt";
    }

    static TParseTree Endwhile_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endwhile"), Spacing), "XCBASIC.Endwhile_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Endwhile_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endwhile"), Spacing), "XCBASIC.Endwhile_stmt"), "Endwhile_stmt")(p);
                memo[tuple(`Endwhile_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Endwhile_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endwhile"), Spacing), "XCBASIC.Endwhile_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endwhile"), Spacing), "XCBASIC.Endwhile_stmt"), "Endwhile_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Endwhile_stmt(GetName g)
    {
        return "XCBASIC.Endwhile_stmt";
    }

    static TParseTree Repeat_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("repeat"), Spacing), "XCBASIC.Repeat_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Repeat_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("repeat"), Spacing), "XCBASIC.Repeat_stmt"), "Repeat_stmt")(p);
                memo[tuple(`Repeat_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Repeat_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("repeat"), Spacing), "XCBASIC.Repeat_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("repeat"), Spacing), "XCBASIC.Repeat_stmt"), "Repeat_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Repeat_stmt(GetName g)
    {
        return "XCBASIC.Repeat_stmt";
    }

    static TParseTree Until_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("until"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "XCBASIC.Until_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Until_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("until"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "XCBASIC.Until_stmt"), "Until_stmt")(p);
                memo[tuple(`Until_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Until_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("until"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "XCBASIC.Until_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("until"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Condition, Spacing)), "XCBASIC.Until_stmt"), "Until_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Until_stmt(GetName g)
    {
        return "XCBASIC.Until_stmt";
    }

    static TParseTree Rem_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(";"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rem"), Spacing)), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, eol, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), Spacing))), "XCBASIC.Rem_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Rem_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(";"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rem"), Spacing)), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, eol, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), Spacing))), "XCBASIC.Rem_stmt"), "Rem_stmt")(p);
                memo[tuple(`Rem_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Rem_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(";"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rem"), Spacing)), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, eol, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), Spacing))), "XCBASIC.Rem_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(";"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rem"), Spacing)), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, eol, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), Spacing))), "XCBASIC.Rem_stmt"), "Rem_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Rem_stmt(GetName g)
    {
        return "XCBASIC.Rem_stmt";
    }

    static TParseTree For_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("for"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("to"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("step"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.For_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`For_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("for"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("to"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("step"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.For_stmt"), "For_stmt")(p);
                memo[tuple(`For_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree For_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("for"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("to"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("step"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.For_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("for"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("to"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("step"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.For_stmt"), "For_stmt")(TParseTree("", false,[], s));
        }
    }
    static string For_stmt(GetName g)
    {
        return "XCBASIC.For_stmt";
    }

    static TParseTree Next_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("next"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Var, Spacing))), "XCBASIC.Next_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Next_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("next"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Var, Spacing))), "XCBASIC.Next_stmt"), "Next_stmt")(p);
                memo[tuple(`Next_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Next_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("next"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Var, Spacing))), "XCBASIC.Next_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("next"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Var, Spacing))), "XCBASIC.Next_stmt"), "Next_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Next_stmt(GetName g)
    {
        return "XCBASIC.Next_stmt";
    }

    static TParseTree Dim_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dim"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fast"), Spacing)), Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("@"), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Dim_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Dim_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dim"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fast"), Spacing)), Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("@"), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Dim_stmt"), "Dim_stmt")(p);
                memo[tuple(`Dim_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Dim_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dim"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fast"), Spacing)), Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("@"), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Dim_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dim"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fast"), Spacing)), Spacing)), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("@"), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Dim_stmt"), "Dim_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Dim_stmt(GetName g)
    {
        return "XCBASIC.Dim_stmt";
    }

    static TParseTree Data_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("data"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("[]"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Datalist, Spacing), pegged.peg.wrapAround!(Spacing, Incbin_stmt, Spacing)), Spacing)), "XCBASIC.Data_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Data_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("data"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("[]"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Datalist, Spacing), pegged.peg.wrapAround!(Spacing, Incbin_stmt, Spacing)), Spacing)), "XCBASIC.Data_stmt"), "Data_stmt")(p);
                memo[tuple(`Data_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Data_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("data"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("[]"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Datalist, Spacing), pegged.peg.wrapAround!(Spacing, Incbin_stmt, Spacing)), Spacing)), "XCBASIC.Data_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("data"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("[]"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Datalist, Spacing), pegged.peg.wrapAround!(Spacing, Incbin_stmt, Spacing)), Spacing)), "XCBASIC.Data_stmt"), "Data_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Data_stmt(GetName g)
    {
        return "XCBASIC.Data_stmt";
    }

    static TParseTree Charat_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("charat"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Charat_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Charat_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("charat"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Charat_stmt"), "Charat_stmt")(p);
                memo[tuple(`Charat_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Charat_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("charat"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Charat_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("charat"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Charat_stmt"), "Charat_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Charat_stmt(GetName g)
    {
        return "XCBASIC.Charat_stmt";
    }

    static TParseTree Textat_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("textat"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing)), "XCBASIC.Textat_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Textat_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("textat"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing)), "XCBASIC.Textat_stmt"), "Textat_stmt")(p);
                memo[tuple(`Textat_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Textat_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("textat"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing)), "XCBASIC.Textat_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("textat"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing)), "XCBASIC.Textat_stmt"), "Textat_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Textat_stmt(GetName g)
    {
        return "XCBASIC.Textat_stmt";
    }

    static TParseTree Asm_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asm"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Asm_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Asm_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asm"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Asm_stmt"), "Asm_stmt")(p);
                memo[tuple(`Asm_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Asm_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asm"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Asm_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asm"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Asm_stmt"), "Asm_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Asm_stmt(GetName g)
    {
        return "XCBASIC.Asm_stmt";
    }

    static TParseTree Incbin_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("incbin"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Incbin_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Incbin_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("incbin"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Incbin_stmt"), "Incbin_stmt")(p);
                memo[tuple(`Incbin_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Incbin_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("incbin"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Incbin_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("incbin"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Incbin_stmt"), "Incbin_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Incbin_stmt(GetName g)
    {
        return "XCBASIC.Incbin_stmt";
    }

    static TParseTree Include_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("include"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Include_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Include_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("include"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Include_stmt"), "Include_stmt")(p);
                memo[tuple(`Include_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Include_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("include"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Include_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("include"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing)), "XCBASIC.Include_stmt"), "Include_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Include_stmt(GetName g)
    {
        return "XCBASIC.Include_stmt";
    }

    static TParseTree Inc_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inc"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), "XCBASIC.Inc_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Inc_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inc"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), "XCBASIC.Inc_stmt"), "Inc_stmt")(p);
                memo[tuple(`Inc_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Inc_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inc"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), "XCBASIC.Inc_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inc"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), "XCBASIC.Inc_stmt"), "Inc_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Inc_stmt(GetName g)
    {
        return "XCBASIC.Inc_stmt";
    }

    static TParseTree Dec_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dec"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), "XCBASIC.Dec_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Dec_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dec"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), "XCBASIC.Dec_stmt"), "Dec_stmt")(p);
                memo[tuple(`Dec_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Dec_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dec"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), "XCBASIC.Dec_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dec"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), "XCBASIC.Dec_stmt"), "Dec_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Dec_stmt(GetName g)
    {
        return "XCBASIC.Dec_stmt";
    }

    static TParseTree Proc_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("proc"), Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, VarList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), Spacing))), "XCBASIC.Proc_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Proc_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("proc"), Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, VarList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), Spacing))), "XCBASIC.Proc_stmt"), "Proc_stmt")(p);
                memo[tuple(`Proc_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Proc_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("proc"), Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, VarList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), Spacing))), "XCBASIC.Proc_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("proc"), Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, VarList, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), Spacing))), "XCBASIC.Proc_stmt"), "Proc_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Proc_stmt(GetName g)
    {
        return "XCBASIC.Proc_stmt";
    }

    static TParseTree Fun_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fun"), Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, VarList, Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), "XCBASIC.Fun_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Fun_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fun"), Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, VarList, Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), "XCBASIC.Fun_stmt"), "Fun_stmt")(p);
                memo[tuple(`Fun_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Fun_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fun"), Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, VarList, Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), "XCBASIC.Fun_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fun"), Spacing), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, WS, Spacing)), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, VarList, Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), "XCBASIC.Fun_stmt"), "Fun_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Fun_stmt(GetName g)
    {
        return "XCBASIC.Fun_stmt";
    }

    static TParseTree Endproc_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endproc"), Spacing), "XCBASIC.Endproc_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Endproc_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endproc"), Spacing), "XCBASIC.Endproc_stmt"), "Endproc_stmt")(p);
                memo[tuple(`Endproc_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Endproc_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endproc"), Spacing), "XCBASIC.Endproc_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endproc"), Spacing), "XCBASIC.Endproc_stmt"), "Endproc_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Endproc_stmt(GetName g)
    {
        return "XCBASIC.Endproc_stmt";
    }

    static TParseTree Endfun_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endfun"), Spacing), "XCBASIC.Endfun_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Endfun_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endfun"), Spacing), "XCBASIC.Endfun_stmt"), "Endfun_stmt")(p);
                memo[tuple(`Endfun_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Endfun_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endfun"), Spacing), "XCBASIC.Endfun_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endfun"), Spacing), "XCBASIC.Endfun_stmt"), "Endfun_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Endfun_stmt(GetName g)
    {
        return "XCBASIC.Endfun_stmt";
    }

    static TParseTree Sys_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sys"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Sys_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Sys_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sys"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Sys_stmt"), "Sys_stmt")(p);
                memo[tuple(`Sys_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Sys_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sys"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Sys_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sys"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Sys_stmt"), "Sys_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Sys_stmt(GetName g)
    {
        return "XCBASIC.Sys_stmt";
    }

    static TParseTree Load_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("load"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Load_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Load_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("load"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Load_stmt"), "Load_stmt")(p);
                memo[tuple(`Load_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Load_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("load"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Load_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("load"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Load_stmt"), "Load_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Load_stmt(GetName g)
    {
        return "XCBASIC.Load_stmt";
    }

    static TParseTree Save_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("save"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Save_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Save_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("save"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Save_stmt"), "Save_stmt")(p);
                memo[tuple(`Save_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Save_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("save"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Save_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("save"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Save_stmt"), "Save_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Save_stmt(GetName g)
    {
        return "XCBASIC.Save_stmt";
    }

    static TParseTree Origin_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("origin"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Origin_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Origin_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("origin"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Origin_stmt"), "Origin_stmt")(p);
                memo[tuple(`Origin_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Origin_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("origin"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Origin_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("origin"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Origin_stmt"), "Origin_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Origin_stmt(GetName g)
    {
        return "XCBASIC.Origin_stmt";
    }

    static TParseTree Strcpy_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Strcpy_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Strcpy_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Strcpy_stmt"), "Strcpy_stmt")(p);
                memo[tuple(`Strcpy_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Strcpy_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Strcpy_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Strcpy_stmt"), "Strcpy_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Strcpy_stmt(GetName g)
    {
        return "XCBASIC.Strcpy_stmt";
    }

    static TParseTree Strncpy_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strncpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Strncpy_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Strncpy_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strncpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Strncpy_stmt"), "Strncpy_stmt")(p);
                memo[tuple(`Strncpy_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Strncpy_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strncpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Strncpy_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strncpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Strncpy_stmt"), "Strncpy_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Strncpy_stmt(GetName g)
    {
        return "XCBASIC.Strncpy_stmt";
    }

    static TParseTree Curpos_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("curpos"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Curpos_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Curpos_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("curpos"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Curpos_stmt"), "Curpos_stmt")(p);
                memo[tuple(`Curpos_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Curpos_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("curpos"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Curpos_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("curpos"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Curpos_stmt"), "Curpos_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Curpos_stmt(GetName g)
    {
        return "XCBASIC.Curpos_stmt";
    }

    static TParseTree On_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("on"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Branch_type, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing)), Spacing))), "XCBASIC.On_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`On_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("on"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Branch_type, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing)), Spacing))), "XCBASIC.On_stmt"), "On_stmt")(p);
                memo[tuple(`On_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree On_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("on"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Branch_type, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing)), Spacing))), "XCBASIC.On_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("on"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Branch_type, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Label_ref, Spacing)), Spacing))), "XCBASIC.On_stmt"), "On_stmt")(TParseTree("", false,[], s));
        }
    }
    static string On_stmt(GetName g)
    {
        return "XCBASIC.On_stmt";
    }

    static TParseTree Wait_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("wait"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Wait_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Wait_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("wait"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Wait_stmt"), "Wait_stmt")(p);
                memo[tuple(`Wait_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Wait_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("wait"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Wait_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("wait"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.Wait_stmt"), "Wait_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Wait_stmt(GetName g)
    {
        return "XCBASIC.Wait_stmt";
    }

    static TParseTree Watch_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("watch"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Watch_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Watch_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("watch"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Watch_stmt"), "Watch_stmt")(p);
                memo[tuple(`Watch_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Watch_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("watch"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Watch_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("watch"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Watch_stmt"), "Watch_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Watch_stmt(GetName g)
    {
        return "XCBASIC.Watch_stmt";
    }

    static TParseTree Pragma_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("pragma"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Id, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Pragma_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Pragma_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("pragma"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Id, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Pragma_stmt"), "Pragma_stmt")(p);
                memo[tuple(`Pragma_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Pragma_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("pragma"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Id, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Pragma_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("pragma"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Id, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Number, Spacing)), "XCBASIC.Pragma_stmt"), "Pragma_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Pragma_stmt(GetName g)
    {
        return "XCBASIC.Pragma_stmt";
    }

    static TParseTree Memset_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memset"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memset_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Memset_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memset"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memset_stmt"), "Memset_stmt")(p);
                memo[tuple(`Memset_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Memset_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memset"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memset_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memset"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memset_stmt"), "Memset_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Memset_stmt(GetName g)
    {
        return "XCBASIC.Memset_stmt";
    }

    static TParseTree Memcpy_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memcpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memcpy_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Memcpy_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memcpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memcpy_stmt"), "Memcpy_stmt")(p);
                memo[tuple(`Memcpy_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Memcpy_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memcpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memcpy_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memcpy"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memcpy_stmt"), "Memcpy_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Memcpy_stmt(GetName g)
    {
        return "XCBASIC.Memcpy_stmt";
    }

    static TParseTree Memshift_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memshift"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memshift_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Memshift_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memshift"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memshift_stmt"), "Memshift_stmt")(p);
                memo[tuple(`Memshift_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Memshift_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memshift"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memshift_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memshift"), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Memshift_stmt"), "Memshift_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Memshift_stmt(GetName g)
    {
        return "XCBASIC.Memshift_stmt";
    }

    static TParseTree Disableirq_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("disableirq"), Spacing), "XCBASIC.Disableirq_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Disableirq_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("disableirq"), Spacing), "XCBASIC.Disableirq_stmt"), "Disableirq_stmt")(p);
                memo[tuple(`Disableirq_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Disableirq_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("disableirq"), Spacing), "XCBASIC.Disableirq_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("disableirq"), Spacing), "XCBASIC.Disableirq_stmt"), "Disableirq_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Disableirq_stmt(GetName g)
    {
        return "XCBASIC.Disableirq_stmt";
    }

    static TParseTree Enableirq_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("enableirq"), Spacing), "XCBASIC.Enableirq_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`Enableirq_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("enableirq"), Spacing), "XCBASIC.Enableirq_stmt"), "Enableirq_stmt")(p);
                memo[tuple(`Enableirq_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Enableirq_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("enableirq"), Spacing), "XCBASIC.Enableirq_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("enableirq"), Spacing), "XCBASIC.Enableirq_stmt"), "Enableirq_stmt")(TParseTree("", false,[], s));
        }
    }
    static string Enableirq_stmt(GetName g)
    {
        return "XCBASIC.Enableirq_stmt";
    }

    static TParseTree End_stmt(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("end"), Spacing), "XCBASIC.End_stmt")(p);
        }
        else
        {
            if (auto m = tuple(`End_stmt`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("end"), Spacing), "XCBASIC.End_stmt"), "End_stmt")(p);
                memo[tuple(`End_stmt`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree End_stmt(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("end"), Spacing), "XCBASIC.End_stmt")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("end"), Spacing), "XCBASIC.End_stmt"), "End_stmt")(TParseTree("", false,[], s));
        }
    }
    static string End_stmt(GetName g)
    {
        return "XCBASIC.End_stmt";
    }

    static TParseTree Userdef_cmd(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, ExprList, Spacing))), "XCBASIC.Userdef_cmd")(p);
        }
        else
        {
            if (auto m = tuple(`Userdef_cmd`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, ExprList, Spacing))), "XCBASIC.Userdef_cmd"), "Userdef_cmd")(p);
                memo[tuple(`Userdef_cmd`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Userdef_cmd(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, ExprList, Spacing))), "XCBASIC.Userdef_cmd")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Label_ref, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, ExprList, Spacing))), "XCBASIC.Userdef_cmd"), "Userdef_cmd")(TParseTree("", false,[], s));
        }
    }
    static string Userdef_cmd(GetName g)
    {
        return "XCBASIC.Userdef_cmd";
    }

    static TParseTree Branch_type(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing)), "XCBASIC.Branch_type")(p);
        }
        else
        {
            if (auto m = tuple(`Branch_type`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing)), "XCBASIC.Branch_type"), "Branch_type")(p);
                memo[tuple(`Branch_type`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Branch_type(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing)), "XCBASIC.Branch_type")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing)), "XCBASIC.Branch_type"), "Branch_type")(TParseTree("", false,[], s));
        }
    }
    static string Branch_type(GetName g)
    {
        return "XCBASIC.Branch_type";
    }

    static TParseTree Relation(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Relop, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Relation")(p);
        }
        else
        {
            if (auto m = tuple(`Relation`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Relop, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Relation"), "Relation")(p);
                memo[tuple(`Relation`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Relation(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Relop, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Relation")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Relop, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), "XCBASIC.Relation"), "Relation")(TParseTree("", false,[], s));
        }
    }
    static string Relation(GetName g)
    {
        return "XCBASIC.Relation";
    }

    static TParseTree Condition(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Relation, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Logop, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Relation, Spacing)), Spacing))), "XCBASIC.Condition")(p);
        }
        else
        {
            if (auto m = tuple(`Condition`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Relation, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Logop, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Relation, Spacing)), Spacing))), "XCBASIC.Condition"), "Condition")(p);
                memo[tuple(`Condition`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Condition(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Relation, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Logop, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Relation, Spacing)), Spacing))), "XCBASIC.Condition")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Relation, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Logop, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Relation, Spacing)), Spacing))), "XCBASIC.Condition"), "Condition")(TParseTree("", false,[], s));
        }
    }
    static string Condition(GetName g)
    {
        return "XCBASIC.Condition";
    }

    static TParseTree ExprList(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.ExprList")(p);
        }
        else
        {
            if (auto m = tuple(`ExprList`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.ExprList"), "ExprList")(p);
                memo[tuple(`ExprList`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree ExprList(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.ExprList")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing)), Spacing))), "XCBASIC.ExprList"), "ExprList")(TParseTree("", false,[], s));
        }
    }
    static string ExprList(GetName g)
    {
        return "XCBASIC.ExprList";
    }

    static TParseTree VarList(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), Spacing))), "XCBASIC.VarList")(p);
        }
        else
        {
            if (auto m = tuple(`VarList`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), Spacing))), "XCBASIC.VarList"), "VarList")(p);
                memo[tuple(`VarList`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree VarList(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), Spacing))), "XCBASIC.VarList")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Var, Spacing)), Spacing))), "XCBASIC.VarList"), "VarList")(TParseTree("", false,[], s));
        }
    }
    static string VarList(GetName g)
    {
        return "XCBASIC.VarList";
    }

    static TParseTree Datalist(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Datalist")(p);
        }
        else
        {
            if (auto m = tuple(`Datalist`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Datalist"), "Datalist")(p);
                memo[tuple(`Datalist`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Datalist(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Datalist")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(","), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Datalist"), "Datalist")(TParseTree("", false,[], s));
        }
    }
    static string Datalist(GetName g)
    {
        return "XCBASIC.Datalist";
    }

    static TParseTree Expression(TParseTree p)
    {
        if(__ctfe)
        {
            assert(false, "Expression is left-recursive, which is not supported at compile-time. Consider using asModule().");
        }
        else
        {
            static TParseTree[size_t /*position*/] seed;
            if (auto s = p.end in seed)
                return *s;
            if (!blockMemoAtPos.canFind(p.end))
                if (auto m = tuple(`Expression`, p.end) in memo)
                    return *m;
            auto current = fail(p);
            seed[p.end] = current;
            blockMemoAtPos ~= p.end;
            while (true)
            {
                auto result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Simplexp, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, BW_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Simplexp, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Expression"), "Expression")(p);
                if (result.end > current.end ||
                    (!current.successful && result.successful) /* null-match */)
                {
                    current = result;
                    seed[p.end] = current;
                } else {
                    seed.remove(p.end);
                    assert(blockMemoAtPos.canFind(p.end));
                    blockMemoAtPos = blockMemoAtPos.remove(countUntil(blockMemoAtPos, p.end));
                    memo[tuple(`Expression`, p.end)] = current;
                    return current;
                }
            }
        }
    }

    static TParseTree Expression(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Simplexp, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, BW_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Simplexp, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Expression")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Simplexp, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, BW_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Simplexp, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Expression"), "Expression")(TParseTree("", false,[], s));
        }
    }
    static string Expression(GetName g)
    {
        return "XCBASIC.Expression";
    }

    static TParseTree Simplexp(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, E_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Simplexp")(p);
        }
        else
        {
            if (blockMemoAtPos.canFind(p.end))
                return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, E_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Simplexp"), "Simplexp")(p);
            if (auto m = tuple(`Simplexp`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, E_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Simplexp"), "Simplexp")(p);
                memo[tuple(`Simplexp`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Simplexp(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, E_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Simplexp")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, E_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Term, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Simplexp"), "Simplexp")(TParseTree("", false,[], s));
        }
    }
    static string Simplexp(GetName g)
    {
        return "XCBASIC.Simplexp";
    }

    static TParseTree Term(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, T_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Term")(p);
        }
        else
        {
            if (blockMemoAtPos.canFind(p.end))
                return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, T_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Term"), "Term")(p);
            if (auto m = tuple(`Term`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, T_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Term"), "Term")(p);
                memo[tuple(`Term`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Term(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, T_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Term")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, T_OP, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Factor, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing)))), Spacing))), "XCBASIC.Term"), "Term")(TParseTree("", false,[], s));
        }
    }
    static string Term(GetName g)
    {
        return "XCBASIC.Term";
    }

    static TParseTree Factor(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Fn_call, Spacing), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, Parenthesis, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.wrapAround!(Spacing, Address, Spacing)), Spacing), "XCBASIC.Factor")(p);
        }
        else
        {
            if (blockMemoAtPos.canFind(p.end))
                return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Fn_call, Spacing), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, Parenthesis, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.wrapAround!(Spacing, Address, Spacing)), Spacing), "XCBASIC.Factor"), "Factor")(p);
            if (auto m = tuple(`Factor`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Fn_call, Spacing), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, Parenthesis, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.wrapAround!(Spacing, Address, Spacing)), Spacing), "XCBASIC.Factor"), "Factor")(p);
                memo[tuple(`Factor`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Factor(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Fn_call, Spacing), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, Parenthesis, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.wrapAround!(Spacing, Address, Spacing)), Spacing), "XCBASIC.Factor")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Fn_call, Spacing), pegged.peg.wrapAround!(Spacing, Var, Spacing), pegged.peg.wrapAround!(Spacing, Number, Spacing), pegged.peg.wrapAround!(Spacing, Parenthesis, Spacing), pegged.peg.wrapAround!(Spacing, String, Spacing), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.wrapAround!(Spacing, Address, Spacing)), Spacing), "XCBASIC.Factor"), "Factor")(TParseTree("", false,[], s));
        }
    }
    static string Factor(GetName g)
    {
        return "XCBASIC.Factor";
    }

    static TParseTree Fn_call(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Id, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "XCBASIC.Fn_call")(p);
        }
        else
        {
            if (auto m = tuple(`Fn_call`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Id, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "XCBASIC.Fn_call"), "Fn_call")(p);
                memo[tuple(`Fn_call`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Fn_call(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Id, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "XCBASIC.Fn_call")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Id, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, ExprList, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing)), "XCBASIC.Fn_call"), "Fn_call")(TParseTree("", false,[], s));
        }
    }
    static string Fn_call(GetName g)
    {
        return "XCBASIC.Fn_call";
    }

    static TParseTree Var(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Subscript, Spacing))), "XCBASIC.Var")(p);
        }
        else
        {
            if (auto m = tuple(`Var`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Subscript, Spacing))), "XCBASIC.Var"), "Var")(p);
                memo[tuple(`Var`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Var(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Subscript, Spacing))), "XCBASIC.Var")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Subscript, Spacing))), "XCBASIC.Var"), "Var")(TParseTree("", false,[], s));
        }
    }
    static string Var(GetName g)
    {
        return "XCBASIC.Var";
    }

    static TParseTree Parenthesis(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), "XCBASIC.Parenthesis")(p);
        }
        else
        {
            if (auto m = tuple(`Parenthesis`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), "XCBASIC.Parenthesis"), "Parenthesis")(p);
                memo[tuple(`Parenthesis`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Parenthesis(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), "XCBASIC.Parenthesis")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("("), Spacing)), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.wrapAround!(Spacing, Expression, Spacing), pegged.peg.discard!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, WS, Spacing))), pegged.peg.discard!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(")"), Spacing))), "XCBASIC.Parenthesis"), "Parenthesis")(TParseTree("", false,[], s));
        }
    }
    static string Parenthesis(GetName g)
    {
        return "XCBASIC.Parenthesis";
    }

    static TParseTree T_OP(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("/"), Spacing)), Spacing), "XCBASIC.T_OP")(p);
        }
        else
        {
            if (auto m = tuple(`T_OP`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("/"), Spacing)), Spacing), "XCBASIC.T_OP"), "T_OP")(p);
                memo[tuple(`T_OP`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree T_OP(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("/"), Spacing)), Spacing), "XCBASIC.T_OP")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("*"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("/"), Spacing)), Spacing), "XCBASIC.T_OP"), "T_OP")(TParseTree("", false,[], s));
        }
    }
    static string T_OP(GetName g)
    {
        return "XCBASIC.T_OP";
    }

    static TParseTree E_OP(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("+"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), Spacing), "XCBASIC.E_OP")(p);
        }
        else
        {
            if (auto m = tuple(`E_OP`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("+"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), Spacing), "XCBASIC.E_OP"), "E_OP")(p);
                memo[tuple(`E_OP`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree E_OP(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("+"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), Spacing), "XCBASIC.E_OP")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("+"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), Spacing), "XCBASIC.E_OP"), "E_OP")(TParseTree("", false,[], s));
        }
    }
    static string E_OP(GetName g)
    {
        return "XCBASIC.E_OP";
    }

    static TParseTree BW_OP(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("&"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("|"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("^"), Spacing)), Spacing), "XCBASIC.BW_OP")(p);
        }
        else
        {
            if (auto m = tuple(`BW_OP`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("&"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("|"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("^"), Spacing)), Spacing), "XCBASIC.BW_OP"), "BW_OP")(p);
                memo[tuple(`BW_OP`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree BW_OP(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("&"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("|"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("^"), Spacing)), Spacing), "XCBASIC.BW_OP")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("&"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("|"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("^"), Spacing)), Spacing), "XCBASIC.BW_OP"), "BW_OP")(TParseTree("", false,[], s));
        }
    }
    static string BW_OP(GetName g)
    {
        return "XCBASIC.BW_OP";
    }

    static TParseTree Varname(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.negLookahead!(Reserved), pegged.peg.option!(pegged.peg.literal!("\\")), pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')))), "XCBASIC.Varname")(p);
        }
        else
        {
            if (auto m = tuple(`Varname`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.negLookahead!(Reserved), pegged.peg.option!(pegged.peg.literal!("\\")), pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')))), "XCBASIC.Varname"), "Varname")(p);
                memo[tuple(`Varname`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Varname(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.negLookahead!(Reserved), pegged.peg.option!(pegged.peg.literal!("\\")), pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')))), "XCBASIC.Varname")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.negLookahead!(Reserved), pegged.peg.option!(pegged.peg.literal!("\\")), pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')))), "XCBASIC.Varname"), "Varname")(TParseTree("", false,[], s));
        }
    }
    static string Varname(GetName g)
    {
        return "XCBASIC.Varname";
    }

    static TParseTree Address(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("@"), Spacing), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Subscript, Spacing))), "XCBASIC.Address")(p);
        }
        else
        {
            if (auto m = tuple(`Address`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("@"), Spacing), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Subscript, Spacing))), "XCBASIC.Address"), "Address")(p);
                memo[tuple(`Address`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Address(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("@"), Spacing), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Subscript, Spacing))), "XCBASIC.Address")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("@"), Spacing), pegged.peg.wrapAround!(Spacing, Varname, Spacing), pegged.peg.wrapAround!(Spacing, Vartype, Spacing), pegged.peg.option!(pegged.peg.wrapAround!(Spacing, Subscript, Spacing))), "XCBASIC.Address"), "Address")(TParseTree("", false,[], s));
        }
    }
    static string Address(GetName g)
    {
        return "XCBASIC.Address";
    }

    static TParseTree Id(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')))), "XCBASIC.Id")(p);
        }
        else
        {
            if (auto m = tuple(`Id`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')))), "XCBASIC.Id"), "Id")(p);
                memo[tuple(`Id`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Id(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')))), "XCBASIC.Id")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), pegged.peg.zeroOrMore!(pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')))), "XCBASIC.Id"), "Id")(TParseTree("", false,[], s));
        }
    }
    static string Id(GetName g)
    {
        return "XCBASIC.Id";
    }

    static TParseTree Vartype(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.literal!("%"), pegged.peg.literal!("#"), pegged.peg.literal!("!"), pegged.peg.literal!("$"), eps), "XCBASIC.Vartype")(p);
        }
        else
        {
            if (auto m = tuple(`Vartype`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.literal!("%"), pegged.peg.literal!("#"), pegged.peg.literal!("!"), pegged.peg.literal!("$"), eps), "XCBASIC.Vartype"), "Vartype")(p);
                memo[tuple(`Vartype`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Vartype(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.literal!("%"), pegged.peg.literal!("#"), pegged.peg.literal!("!"), pegged.peg.literal!("$"), eps), "XCBASIC.Vartype")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.literal!("%"), pegged.peg.literal!("#"), pegged.peg.literal!("!"), pegged.peg.literal!("$"), eps), "XCBASIC.Vartype"), "Vartype")(TParseTree("", false,[], s));
        }
    }
    static string Vartype(GetName g)
    {
        return "XCBASIC.Vartype";
    }

    static TParseTree Subscript(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.literal!("["), Expression, pegged.peg.option!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(WS)), pegged.peg.literal!(","), pegged.peg.discard!(pegged.peg.option!(WS)), Expression)), pegged.peg.literal!("]")), "XCBASIC.Subscript")(p);
        }
        else
        {
            if (auto m = tuple(`Subscript`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.literal!("["), Expression, pegged.peg.option!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(WS)), pegged.peg.literal!(","), pegged.peg.discard!(pegged.peg.option!(WS)), Expression)), pegged.peg.literal!("]")), "XCBASIC.Subscript"), "Subscript")(p);
                memo[tuple(`Subscript`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Subscript(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.literal!("["), Expression, pegged.peg.option!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(WS)), pegged.peg.literal!(","), pegged.peg.discard!(pegged.peg.option!(WS)), Expression)), pegged.peg.literal!("]")), "XCBASIC.Subscript")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.literal!("["), Expression, pegged.peg.option!(pegged.peg.and!(pegged.peg.discard!(pegged.peg.option!(WS)), pegged.peg.literal!(","), pegged.peg.discard!(pegged.peg.option!(WS)), Expression)), pegged.peg.literal!("]")), "XCBASIC.Subscript"), "Subscript")(TParseTree("", false,[], s));
        }
    }
    static string Subscript(GetName g)
    {
        return "XCBASIC.Subscript";
    }

    static TParseTree Logop(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.longest_match!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing)), "XCBASIC.Logop")(p);
        }
        else
        {
            if (auto m = tuple(`Logop`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.longest_match!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing)), "XCBASIC.Logop"), "Logop")(p);
                memo[tuple(`Logop`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Logop(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.longest_match!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing)), "XCBASIC.Logop")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.longest_match!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing)), "XCBASIC.Logop"), "Logop")(TParseTree("", false,[], s));
        }
    }
    static string Logop(GetName g)
    {
        return "XCBASIC.Logop";
    }

    static TParseTree Relop(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.longest_match!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<>"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">="), Spacing)), "XCBASIC.Relop")(p);
        }
        else
        {
            if (auto m = tuple(`Relop`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.longest_match!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<>"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">="), Spacing)), "XCBASIC.Relop"), "Relop")(p);
                memo[tuple(`Relop`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Relop(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.longest_match!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<>"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">="), Spacing)), "XCBASIC.Relop")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.longest_match!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("="), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("<>"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(">="), Spacing)), "XCBASIC.Relop"), "Relop")(TParseTree("", false,[], s));
        }
    }
    static string Relop(GetName g)
    {
        return "XCBASIC.Relop";
    }

    static TParseTree String(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, doublequote, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, doublequote, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), pegged.peg.keep!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(" "), Spacing))), Spacing)), pegged.peg.wrapAround!(Spacing, doublequote, Spacing)), "XCBASIC.String")(p);
        }
        else
        {
            if (auto m = tuple(`String`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, doublequote, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, doublequote, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), pegged.peg.keep!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(" "), Spacing))), Spacing)), pegged.peg.wrapAround!(Spacing, doublequote, Spacing)), "XCBASIC.String"), "String")(p);
                memo[tuple(`String`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree String(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, doublequote, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, doublequote, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), pegged.peg.keep!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(" "), Spacing))), Spacing)), pegged.peg.wrapAround!(Spacing, doublequote, Spacing)), "XCBASIC.String")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, doublequote, Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, doublequote, Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), pegged.peg.keep!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(" "), Spacing))), Spacing)), pegged.peg.wrapAround!(Spacing, doublequote, Spacing)), "XCBASIC.String"), "String")(TParseTree("", false,[], s));
        }
    }
    static string String(GetName g)
    {
        return "XCBASIC.String";
    }

    static TParseTree Unsigned(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing)), "XCBASIC.Unsigned")(p);
        }
        else
        {
            if (auto m = tuple(`Unsigned`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing)), "XCBASIC.Unsigned"), "Unsigned")(p);
                memo[tuple(`Unsigned`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Unsigned(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing)), "XCBASIC.Unsigned")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.charRange!('0', '9'), Spacing)), "XCBASIC.Unsigned"), "Unsigned")(TParseTree("", false,[], s));
        }
    }
    static string Unsigned(GetName g)
    {
        return "XCBASIC.Unsigned";
    }

    static TParseTree Integer(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), "XCBASIC.Integer")(p);
        }
        else
        {
            if (auto m = tuple(`Integer`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), "XCBASIC.Integer"), "Integer")(p);
                memo[tuple(`Integer`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Integer(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), "XCBASIC.Integer")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), "XCBASIC.Integer"), "Integer")(TParseTree("", false,[], s));
        }
    }
    static string Integer(GetName g)
    {
        return "XCBASIC.Integer";
    }

    static TParseTree Hexa(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("$"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('0', '9'), pegged.peg.charRange!('a', 'f'), pegged.peg.charRange!('A', 'F')), Spacing))), "XCBASIC.Hexa")(p);
        }
        else
        {
            if (auto m = tuple(`Hexa`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("$"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('0', '9'), pegged.peg.charRange!('a', 'f'), pegged.peg.charRange!('A', 'F')), Spacing))), "XCBASIC.Hexa"), "Hexa")(p);
                memo[tuple(`Hexa`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Hexa(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("$"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('0', '9'), pegged.peg.charRange!('a', 'f'), pegged.peg.charRange!('A', 'F')), Spacing))), "XCBASIC.Hexa")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("$"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('0', '9'), pegged.peg.charRange!('a', 'f'), pegged.peg.charRange!('A', 'F')), Spacing))), "XCBASIC.Hexa"), "Hexa")(TParseTree("", false,[], s));
        }
    }
    static string Hexa(GetName g)
    {
        return "XCBASIC.Hexa";
    }

    static TParseTree Binary(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("%"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("0"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("1"), Spacing)), Spacing))), "XCBASIC.Binary")(p);
        }
        else
        {
            if (auto m = tuple(`Binary`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("%"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("0"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("1"), Spacing)), Spacing))), "XCBASIC.Binary"), "Binary")(p);
                memo[tuple(`Binary`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Binary(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("%"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("0"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("1"), Spacing)), Spacing))), "XCBASIC.Binary")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("%"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("0"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("1"), Spacing)), Spacing))), "XCBASIC.Binary"), "Binary")(TParseTree("", false,[], s));
        }
    }
    static string Binary(GetName g)
    {
        return "XCBASIC.Binary";
    }

    static TParseTree Scientific(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Floating, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("e"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("E"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, Integer, Spacing)), "XCBASIC.Scientific")(p);
        }
        else
        {
            if (auto m = tuple(`Scientific`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Floating, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("e"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("E"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, Integer, Spacing)), "XCBASIC.Scientific"), "Scientific")(p);
                memo[tuple(`Scientific`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Scientific(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Floating, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("e"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("E"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, Integer, Spacing)), "XCBASIC.Scientific")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, Floating, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("e"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("E"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, Integer, Spacing)), "XCBASIC.Scientific"), "Scientific")(TParseTree("", false,[], s));
        }
    }
    static string Scientific(GetName g)
    {
        return "XCBASIC.Scientific";
    }

    static TParseTree Floating(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), "XCBASIC.Floating")(p);
        }
        else
        {
            if (auto m = tuple(`Floating`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), "XCBASIC.Floating"), "Floating")(p);
                memo[tuple(`Floating`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Floating(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), "XCBASIC.Floating")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.option!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("-"), Spacing)), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("."), Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing)), "XCBASIC.Floating"), "Floating")(TParseTree("", false,[], s));
        }
    }
    static string Floating(GetName g)
    {
        return "XCBASIC.Floating";
    }

    static TParseTree Charlit(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'{"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("}'"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing)), Spacing)), "XCBASIC.Charlit")(p);
        }
        else
        {
            if (auto m = tuple(`Charlit`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'{"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("}'"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing)), Spacing)), "XCBASIC.Charlit"), "Charlit")(p);
                memo[tuple(`Charlit`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Charlit(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'{"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("}'"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing)), Spacing)), "XCBASIC.Charlit")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'{"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("}'"), Spacing)), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("'"), Spacing)), Spacing)), "XCBASIC.Charlit"), "Charlit")(TParseTree("", false,[], s));
        }
    }
    static string Charlit(GetName g)
    {
        return "XCBASIC.Charlit";
    }

    static TParseTree Number(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Scientific, Spacing), pegged.peg.wrapAround!(Spacing, Floating, Spacing), pegged.peg.wrapAround!(Spacing, Integer, Spacing), pegged.peg.wrapAround!(Spacing, Hexa, Spacing), pegged.peg.wrapAround!(Spacing, Binary, Spacing), pegged.peg.wrapAround!(Spacing, Charlit, Spacing)), Spacing), "XCBASIC.Number")(p);
        }
        else
        {
            if (auto m = tuple(`Number`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Scientific, Spacing), pegged.peg.wrapAround!(Spacing, Floating, Spacing), pegged.peg.wrapAround!(Spacing, Integer, Spacing), pegged.peg.wrapAround!(Spacing, Hexa, Spacing), pegged.peg.wrapAround!(Spacing, Binary, Spacing), pegged.peg.wrapAround!(Spacing, Charlit, Spacing)), Spacing), "XCBASIC.Number"), "Number")(p);
                memo[tuple(`Number`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Number(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Scientific, Spacing), pegged.peg.wrapAround!(Spacing, Floating, Spacing), pegged.peg.wrapAround!(Spacing, Integer, Spacing), pegged.peg.wrapAround!(Spacing, Hexa, Spacing), pegged.peg.wrapAround!(Spacing, Binary, Spacing), pegged.peg.wrapAround!(Spacing, Charlit, Spacing)), Spacing), "XCBASIC.Number")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Scientific, Spacing), pegged.peg.wrapAround!(Spacing, Floating, Spacing), pegged.peg.wrapAround!(Spacing, Integer, Spacing), pegged.peg.wrapAround!(Spacing, Hexa, Spacing), pegged.peg.wrapAround!(Spacing, Binary, Spacing), pegged.peg.wrapAround!(Spacing, Charlit, Spacing)), Spacing), "XCBASIC.Number"), "Number")(TParseTree("", false,[], s));
        }
    }
    static string Number(GetName g)
    {
        return "XCBASIC.Number";
    }

    static TParseTree Label(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(":"), Spacing)), "XCBASIC.Label")(p);
        }
        else
        {
            if (auto m = tuple(`Label`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(":"), Spacing)), "XCBASIC.Label"), "Label")(p);
                memo[tuple(`Label`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Label(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(":"), Spacing)), "XCBASIC.Label")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing)), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!(":"), Spacing)), "XCBASIC.Label"), "Label")(TParseTree("", false,[], s));
        }
    }
    static string Label(GetName g)
    {
        return "XCBASIC.Label";
    }

    static TParseTree Label_ref(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing))), "XCBASIC.Label_ref")(p);
        }
        else
        {
            if (auto m = tuple(`Label_ref`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing))), "XCBASIC.Label_ref"), "Label_ref")(p);
                memo[tuple(`Label_ref`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Label_ref(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing))), "XCBASIC.Label_ref")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_")), Spacing), pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.charRange!('a', 'z'), pegged.peg.charRange!('A', 'Z'), pegged.peg.literal!("_"), pegged.peg.charRange!('0', '9')), Spacing))), "XCBASIC.Label_ref"), "Label_ref")(TParseTree("", false,[], s));
        }
    }
    static string Label_ref(GetName g)
    {
        return "XCBASIC.Label_ref";
    }

    static TParseTree Line_id(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), "XCBASIC.Line_id")(p);
        }
        else
        {
            if (auto m = tuple(`Line_id`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), "XCBASIC.Line_id"), "Line_id")(p);
                memo[tuple(`Line_id`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Line_id(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), "XCBASIC.Line_id")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, Label, Spacing), pegged.peg.wrapAround!(Spacing, Unsigned, Spacing), pegged.peg.wrapAround!(Spacing, eps, Spacing)), Spacing), "XCBASIC.Line_id"), "Line_id")(TParseTree("", false,[], s));
        }
    }
    static string Line_id(GetName g)
    {
        return "XCBASIC.Line_id";
    }

    static TParseTree Reserved(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("const"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("let"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("print"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("input"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("call"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("end"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rem"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("poke"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("peek"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("for"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("to"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("next"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dim"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("data"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("charat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("textat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inkey"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rnd"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("incbin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dec"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("proc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endproc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sys"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("usr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("origin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("load"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("save"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("ferr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("deek"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("doke"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("abs"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("cast"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("cos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("tan"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("atn"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asm"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strncpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strlen"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcmp"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("curpos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strpos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("val"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sqr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sgn"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("wait"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("watch"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("pragma"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memset"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memcpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("while"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endwhile"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("repeat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("until"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("lshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("disableirq"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("enableirq"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fun"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("step"), Spacing)), Spacing), "XCBASIC.Reserved")(p);
        }
        else
        {
            if (auto m = tuple(`Reserved`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("const"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("let"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("print"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("input"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("call"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("end"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rem"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("poke"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("peek"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("for"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("to"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("next"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dim"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("data"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("charat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("textat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inkey"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rnd"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("incbin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dec"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("proc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endproc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sys"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("usr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("origin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("load"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("save"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("ferr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("deek"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("doke"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("abs"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("cast"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("cos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("tan"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("atn"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asm"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strncpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strlen"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcmp"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("curpos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strpos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("val"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sqr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sgn"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("wait"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("watch"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("pragma"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memset"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memcpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("while"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endwhile"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("repeat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("until"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("lshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("disableirq"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("enableirq"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fun"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("step"), Spacing)), Spacing), "XCBASIC.Reserved"), "Reserved")(p);
                memo[tuple(`Reserved`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Reserved(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("const"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("let"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("print"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("input"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("call"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("end"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rem"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("poke"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("peek"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("for"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("to"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("next"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dim"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("data"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("charat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("textat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inkey"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rnd"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("incbin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dec"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("proc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endproc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sys"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("usr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("origin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("load"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("save"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("ferr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("deek"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("doke"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("abs"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("cast"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("cos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("tan"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("atn"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asm"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strncpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strlen"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcmp"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("curpos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strpos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("val"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sqr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sgn"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("wait"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("watch"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("pragma"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memset"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memcpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("while"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endwhile"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("repeat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("until"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("lshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("disableirq"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("enableirq"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fun"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("step"), Spacing)), Spacing), "XCBASIC.Reserved")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("const"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("let"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("print"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("if"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("then"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("goto"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("input"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("gosub"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("return"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("call"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("end"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rem"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("poke"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("peek"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("for"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("to"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("next"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dim"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("data"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("charat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("textat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inkey"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rnd"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("incbin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("inc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("dec"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("proc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endproc"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sys"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("usr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("and"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("origin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("or"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("load"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("save"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("ferr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("deek"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("doke"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("abs"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("cast"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sin"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("cos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("tan"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("atn"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("asm"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strncpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strlen"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strcmp"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("curpos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("strpos"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("val"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sqr"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("sgn"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("wait"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("watch"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("pragma"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memset"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memcpy"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("memshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("while"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("endwhile"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("repeat"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("until"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("lshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("rshift"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("disableirq"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("enableirq"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("fun"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.caseInsensitiveLiteral!("step"), Spacing)), Spacing), "XCBASIC.Reserved"), "Reserved")(TParseTree("", false,[], s));
        }
    }
    static string Reserved(GetName g)
    {
        return "XCBASIC.Reserved";
    }

    static TParseTree WS(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, space, Spacing), pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("~"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\r"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\n"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\r\n"), Spacing)), Spacing)))), Spacing)), "XCBASIC.WS")(p);
        }
        else
        {
            if (auto m = tuple(`WS`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, space, Spacing), pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("~"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\r"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\n"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\r\n"), Spacing)), Spacing)))), Spacing)), "XCBASIC.WS"), "WS")(p);
                memo[tuple(`WS`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree WS(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, space, Spacing), pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("~"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\r"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\n"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\r\n"), Spacing)), Spacing)))), Spacing)), "XCBASIC.WS")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.zeroOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, space, Spacing), pegged.peg.and!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("~"), Spacing), pegged.peg.oneOrMore!(pegged.peg.wrapAround!(Spacing, pegged.peg.or!(pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\r"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\n"), Spacing), pegged.peg.wrapAround!(Spacing, pegged.peg.literal!("\r\n"), Spacing)), Spacing)))), Spacing)), "XCBASIC.WS"), "WS")(TParseTree("", false,[], s));
        }
    }
    static string WS(GetName g)
    {
        return "XCBASIC.WS";
    }

    static TParseTree EOI(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), "XCBASIC.EOI")(p);
        }
        else
        {
            if (auto m = tuple(`EOI`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), "XCBASIC.EOI"), "EOI")(p);
                memo[tuple(`EOI`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree EOI(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), "XCBASIC.EOI")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.negLookahead!(pegged.peg.wrapAround!(Spacing, pegged.peg.any, Spacing)), "XCBASIC.EOI"), "EOI")(TParseTree("", false,[], s));
        }
    }
    static string EOI(GetName g)
    {
        return "XCBASIC.EOI";
    }

    static TParseTree NL(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.literal!("~")), pegged.peg.oneOrMore!(pegged.peg.keywords!("\r", "\n", "\r\n"))), "XCBASIC.NL")(p);
        }
        else
        {
            if (auto m = tuple(`NL`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.literal!("~")), pegged.peg.oneOrMore!(pegged.peg.keywords!("\r", "\n", "\r\n"))), "XCBASIC.NL"), "NL")(p);
                memo[tuple(`NL`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree NL(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.literal!("~")), pegged.peg.oneOrMore!(pegged.peg.keywords!("\r", "\n", "\r\n"))), "XCBASIC.NL")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.and!(pegged.peg.negLookahead!(pegged.peg.literal!("~")), pegged.peg.oneOrMore!(pegged.peg.keywords!("\r", "\n", "\r\n"))), "XCBASIC.NL"), "NL")(TParseTree("", false,[], s));
        }
    }
    static string NL(GetName g)
    {
        return "XCBASIC.NL";
    }

    static TParseTree Spacing(TParseTree p)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.discard!(pegged.peg.zeroOrMore!(pegged.peg.literal!("\t"))), "XCBASIC.Spacing")(p);
        }
        else
        {
            if (auto m = tuple(`Spacing`, p.end) in memo)
                return *m;
            else
            {
                TParseTree result = hooked!(pegged.peg.defined!(pegged.peg.discard!(pegged.peg.zeroOrMore!(pegged.peg.literal!("\t"))), "XCBASIC.Spacing"), "Spacing")(p);
                memo[tuple(`Spacing`, p.end)] = result;
                return result;
            }
        }
    }

    static TParseTree Spacing(string s)
    {
        if(__ctfe)
        {
            return         pegged.peg.defined!(pegged.peg.discard!(pegged.peg.zeroOrMore!(pegged.peg.literal!("\t"))), "XCBASIC.Spacing")(TParseTree("", false,[], s));
        }
        else
        {
            forgetMemo();
            return hooked!(pegged.peg.defined!(pegged.peg.discard!(pegged.peg.zeroOrMore!(pegged.peg.literal!("\t"))), "XCBASIC.Spacing"), "Spacing")(TParseTree("", false,[], s));
        }
    }
    static string Spacing(GetName g)
    {
        return "XCBASIC.Spacing";
    }

    static TParseTree opCall(TParseTree p)
    {
        TParseTree result = decimateTree(Program(p));
        result.children = [result];
        result.name = "XCBASIC";
        return result;
    }

    static TParseTree opCall(string input)
    {
        if(__ctfe)
        {
            return XCBASIC(TParseTree(``, false, [], input, 0, 0));
        }
        else
        {
            forgetMemo();
            return XCBASIC(TParseTree(``, false, [], input, 0, 0));
        }
    }
    static string opCall(GetName g)
    {
        return "XCBASIC";
    }


    static void forgetMemo()
    {
        memo = null;
    }
    }
}

alias GenericXCBASIC!(ParseTree).XCBASIC XCBASIC;


