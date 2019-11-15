module language.fun;

import pegged.grammar;
import program;
import std.string, std.conv, std.stdio;
import language.expression;
import std.algorithm.mutation, std.algorithm.searching;
import language.stringliteral;

import fun.abs_fun;
import fun.atn_fun;
import fun.cast_fun;
import fun.cos_fun;
import fun.deek_fun;
import fun.ferr_fun;
import fun.inkey_fun;
import fun.peek_fun;
import fun.rnd_fun;
import fun.sgn_fun;
import fun.shift_fun;
import fun.sin_fun;
import fun.sqr_fun;
import fun.strcmp_fun;
import fun.strlen_fun;
import fun.strpos_fun;
import fun.tan_fun;
import fun.userdef_fun;
import fun.usr_fun;
import fun.val_fun;

Fun FunFactory(ParseTree node, Program program) {

    string[] builtin_functions = [
        "peek", "deek", "inkey", "rnd", "usr", "ferr", "abs", "cast",
        "sin", "cos", "tan", "atn", "sqr", "sgn",
        "strlen", "strcmp", "strpos",
        "val", "lshift", "rshift"
    ];

    string funName = join(node.children[0].matches);
    Fun fun;
    if(builtin_functions.find(funName).empty) {

        if(program.procExists(funName)) {
            Procedure proc = program.findProcedure(funName);
            if(!proc.is_function) {
                program.error(funName ~ "is not a function");
            }

            fun = new UserDef_fun(node, program, proc);
        }
        else {
            program.error("Function " ~ funName ~ " not defined");
        }
    }
    else {
        switch (funName) {
            case "peek":
                fun = new Peek_fun(node, program);
            break;

            case "deek":
                fun = new Deek_fun(node, program);
            break;

            case "inkey":
                fun = new Inkey_fun(node, program);
            break;

            case "rnd":
                fun = new Rnd_fun(node, program);
            break;

            case "usr":
                fun = new Usr_fun(node, program);
            break;

            case "ferr":
                fun = new Ferr_fun(node, program);
            break;

            case "abs":
                fun = new Abs_fun(node, program);
            break;

            case "cast":
                fun = new Cast_fun(node, program);
            break;

            case "sin":
                fun = new Sin_fun(node, program);
            break;

            case "cos":
                fun = new Cos_fun(node, program);
            break;

            case "tan":
                fun = new Tan_fun(node, program);
            break;

            case "atn":
                fun = new Atn_fun(node, program);
            break;

            case "sqr":
                fun = new Sqr_fun(node, program);
            break;

            case "sgn":
                fun = new Sgn_fun(node, program);
            break;

            case "strlen":
                fun = new Strlen_fun(node, program);
            break;

            case "strcmp":
                fun = new Strcmp_fun(node, program);
            break;

            case "strpos":
                fun = new Strpos_fun(node, program);
            break;

            case "val":
                fun = new Val_fun(node, program);
            break;

            case "lshift":
                fun = new Shift_fun(node, program);
                fun.direction = "l";
            break;

            case "rshift":
                fun = new Shift_fun(node, program);
                fun.direction = "r";
            break;

            default:
            assert(0);
        }
    }

    return fun;
}

template FunConstructor()
{
    this(ParseTree node, Program program)
    {
        super(node, program);
        if(this.node.children.length > 2) {
            auto exprlist = this.node.children[2];
            if(this.check_argcount) {
                if(exprlist.children.length < this.arg_count || exprlist.children.length > this.arg_count + this.opt_arg_count) {
                    this.program.error("Wrong number of arguments");
                }
            }

            // mandatory arguments
            ubyte i=0;

            while(i < this.arg_count) {
                auto e = exprlist.children[i];
                this.arglist[i] = new Expression(e, this.program);
                this.arglist[i].eval();
                i++;
            }

            // optional arguments

            while(i < exprlist.children.length) {
                auto e = exprlist.children[i];
                this.arglist[i] = new Expression(e, this.program);
                this.arglist[i].eval();
                i++;
            }
        }
        else {
            if(this.check_argcount && this.arg_count > 0) {
                this.program.error("Wrong number of arguments");
            }
        }
    }
}

interface FunInterface
{
    void process();
}

abstract class Fun:FunInterface
{
    protected ParseTree node;
    protected Program program;
    protected ubyte arg_count = 0;
    protected ubyte opt_arg_count = 0;
    protected bool check_argcount = true;
    protected Expression[8] arglist;
    protected string fncode;
    public char type;
    // Currently only used in Shiftfun
    public string direction = "";

    this(ParseTree node, Program program)
    {
        this.node = node;
        string funName = join(node.children[0].matches);
        auto sigil = join(node.children[1].matches);
        char type = program.resolve_sigil(sigil);

        if(count(this.getPossibleTypes(), type) == 0) {
            string err = "The function "~funName ~"() cannot return " ~program.vartype_names[type];
            program.error(err);
        }
        this.program = program;
        this.type = type;
    }

    protected char[] getPossibleTypes()
    {
        return ['w'];
    }

    override string toString()
    {
        string asmcode;
        foreach(ref e; this.arglist) {
            if(e is null) {
                continue;
            }
            asmcode ~= to!string(e);
        }
        asmcode ~= fncode;
        return asmcode;
    }
}

abstract class TrigonometricFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['f'];
    }

    abstract string getName();

    void process()
    {
        if(this.arglist[0].type != 'f') {
            this.program.error("Argument #1 of "~this.getName()~"() must be a float");
        }

        this.fncode = "\t" ~this.getName()~ "f\n";
    }
}
