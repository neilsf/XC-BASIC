module fun;

import pegged.grammar;
import program;
import std.string, std.conv, std.stdio;
import expression;
import std.algorithm.mutation, std.algorithm.searching;
import stringliteral;

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

            fun = new UserDefFun(node, program, proc);
        }
        else {
            program.error("Function " ~ funName ~ " not defined");
        }
    }
    else {
        switch (funName) {
            case "peek":
                fun = new PeekFun(node, program);
            break;

            case "deek":
                fun = new DeekFun(node, program);
            break;

            case "inkey":
                fun = new InKeyFun(node, program);
            break;

            case "rnd":
                fun = new RndFun(node, program);
            break;

            case "usr":
                fun = new UsrFun(node, program);
            break;

            case "ferr":
                fun = new FerrFun(node, program);
            break;

            case "abs":
                fun = new AbsFun(node, program);
            break;

            case "cast":
                fun = new CastFun(node, program);
            break;

            case "sin":
                fun = new SinFun(node, program);
            break;

            case "cos":
                fun = new CosFun(node, program);
            break;

            case "tan":
                fun = new TanFun(node, program);
            break;

            case "atn":
                fun = new AtnFun(node, program);
            break;

            case "sqr":
                fun = new SqrFun(node, program);
            break;

            case "sgn":
                fun = new SgnFun(node, program);
            break;

            case "strlen":
                fun = new StrlenFun(node, program);
            break;

            case "strcmp":
                fun = new StrcmpFun(node, program);
            break;

            case "strpos":
                fun = new StrposFun(node, program);
            break;

            case "val":
                fun = new ValFun(node, program);
            break;

            case "lshift":
                fun = new ShiftFun(node, program);
                fun.direction = "l";
            break;

            case "rshift":
                fun = new ShiftFun(node, program);
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

class PeekFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'b'];
    }

    void process()
    {
        if(this.arglist[0].type == 'b') {
            this.arglist[0].convert('w');
        }
        this.fncode ~= "\tpeek"~to!string(this.type)~"\n";
    }
}

class DeekFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w'];
    }

    void process()
    {
        this.fncode ~= "\tdeek\n";
    }
}

class UsrFun:Fun
{
    // This function can take any number of parameters
    protected ubyte arg_count = 0;

    this(ParseTree node, Program program)
    {
        super(node, program);
        auto e_list = this.node.children[2].children;
        int arg_count = to!int(e_list.length);

        for(int i=0; i < arg_count; i++) {
            int index = arg_count - 1 - i;
            auto e = e_list[i];
            if(e.name == "XCBASIC.Expression") {
                this.arglist[index] = new Expression(e, this.program);
            }
            else if(e.name == "XCBASIC.String") {
                this.arglist[index] = new StringExpression(e, this.program);
            }
            else {
                this.program.error("Syntax error");
            }

            this.arglist[index].eval();
        }
    }

    void process()
    {
        this.fncode ~= "\tusr\n";
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

class RndFun:Fun
{
    mixin FunConstructor;
    protected ubyte arg_count = 0;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'f', 'b'];
    }

    void process()
    {
       this.fncode ~= "\trnd" ~ to!string(this.type) ~ "\n";
    }
}

class InKeyFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 0;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'b'];
    }

    void process()
    {
        this.fncode ~= "\tinkey"~ to!string(this.type) ~"\n";
    }
}

class FerrFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 0;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'b'];
    }

    void process()
    {
        this.fncode ~= "\tferr"~ to!string(this.type) ~"\n";
    }
}

class AbsFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'f'];
    }

    void process()
    {
        if(this.type != this.arglist[0].detect_type()) {
            this.program.error("The abs() function's argument type and return type must match");
        }

        this.fncode ~= "\tabs" ~ to!string(this.type) ~ "\n";
    }
}

class StrlenFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['b'];
    }

    void process()
    {
        if(this.arglist[0].detect_type() != 's') {
            this.program.error("Wrong type passed to strlen()");
        }

        this.program.use_stringlib = true;
        this.fncode ~= "\tstrlen\n";
    }
}

class StrcmpFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 2;

    override protected char[] getPossibleTypes()
    {
        return ['w'];
    }

    void process()
    {
        if(this.arglist[0].detect_type() != 's' || this.arglist[1].detect_type() != 's') {
            this.program.error("Wrong type passed to strcmp()");
        }
        this.program.use_stringlib = true;
        this.fncode ~= "\tstrcmp\n";
    }
}

class StrposFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 2;

    override protected char[] getPossibleTypes()
    {
        return ['b'];
    }

    void process()
    {
        if(this.arglist[0].detect_type() != 's' || this.arglist[1].detect_type() != 's') {
            this.program.error("Wrong type passed to strcmp()");
        }
        this.program.use_stringlib = true;
        this.fncode ~= "\tstrpos\n";
    }
}

class CastFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['b', 'w', 'f'];
    }

    void process()
    {
        char argtype = this.arglist[0].type;
        if(argtype == this.type) {
            this.program.error("Can't cast to the same type");
        }

        if(this.type == 'b') {
            this.program.warning("Possible truncation or loss of precision");
        }

        this.fncode = "\t"~to!string(this.arglist[0].type)~"to"~to!string(this.type)~"\n";
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

class SinFun:TrigonometricFun
{
    mixin FunConstructor;

    override string getName()
    {
        return "sin";
    }
}

class CosFun:TrigonometricFun
{
    mixin FunConstructor;

    override string getName()
    {
        return "cos";
    }
}

class TanFun:TrigonometricFun
{
    mixin FunConstructor;

    override string getName()
    {
        return "tan";
    }
}

class AtnFun:TrigonometricFun
{
    mixin FunConstructor;

    override string getName()
    {
        return "atn";
    }
}


class SqrFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'f'];
    }

    void process()
    {
        if(this.type != this.arglist[0].detect_type()) {
            this.program.error("The sqr() function's argument type and return type must match");
        }

        this.fncode ~= "\tsqr" ~ to!string(this.type) ~ "\n";
    }
}


class ValFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['b', 'w', 'f'];
    }

    void process()
    {
        this.program.use_stringlib = true;
        char argtype = this.arglist[0].type;
        if(argtype != 's') {
            this.program.error("Argument 1 of VAL() must be a string pointer");
        }

        this.fncode = "\tval"~to!string(this.type)~"\n";
    }
}

class SgnFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w'];
    }

    void process()
    {
        char argtype = this.arglist[0].detect_type();

        if(indexOf("bwf", argtype) == -1) {
            this.program.error("The argument passed to SGN must be an int or float");
        }

        if(argtype == 'b') {
            this.arglist[0].convert('w');
        }

        this.fncode ~= "\tsgn" ~ to!string(this.type) ~ "\n";
    }
}

class ShiftFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;
    protected ubyte opt_arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['b', 'w'];
    }

    void process()
    {
        if(this.type != this.arglist[0].detect_type()) {
            this.program.error(this.direction ~ "shift(): argument and return types must match");
        }

        bool is_const;
        ubyte cval;

        if(this.arglist[1] !is null) {

            if(this.arglist[1].detect_type() != 'b') {
                this.program.error("Argument #2 of lshift() must be a byte");
            }

            is_const = this.arglist[1].is_const;
            if(is_const) {
                cval = cast(ubyte)this.arglist[1].get_constval();
                this.arglist[1] = null;
            }
        }
        else {
            is_const = true;
            cval = 1;
        }

        this.fncode ~= "\t" ~ this.direction ~  "shift" ~ to!string(this.type) ~ (is_const ? ("c " ~ to!string(cval)) : "") ~ "\n";
    }
}

class UserDefFun : Fun
{
    Procedure proc;

    this(ParseTree node, Program program, Procedure proc)
    {
        this.proc = proc;

        super(node, program);

        if(node.children.length > 2) {
            auto exprlist = node.children[2];
            if(exprlist.children.length != proc.arguments.length) {
                this.program.error("Wrong number of arguments");
            }

            ubyte i=0;
            while(i < exprlist.children.length) {
                auto e = exprlist.children[i];
                this.arglist[i] = new Expression(e, this.program);
                this.arglist[i].eval();
                if(this.arglist[i].type != proc.arguments[i].type) {
                    // Do implicit conversion
                    this.arglist[i].convert(proc.arguments[i].type);
                }
                i++;
            }
        }
    }

    override protected char[] getPossibleTypes()
    {
        return [this.proc.type];
    }

    void process()
    {
        this.fncode ~= "\tjsr " ~ this.proc.getLabel() ~ "\n";
    }

    override string toString()
    {
        string asmcode;
        for(ubyte i = 0; i < this.proc.arguments.length; i++) {
            asmcode ~= to!string(this.arglist[i]);
            char vartype = this.proc.arguments[i].type;
            string varlabel = this.proc.arguments[i].getLabel();
            asmcode ~= "\tpl" ~ to!string(vartype) ~ "2var " ~ varlabel ~ "\n";
        }

        asmcode ~= fncode;
        return asmcode;
    }
}
