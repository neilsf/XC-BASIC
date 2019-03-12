module fun;

import pegged.grammar;
import program;
import std.string, std.conv, std.stdio;
import expression;
import std.algorithm.mutation;
import stringliteral;

Fun FunFactory(ParseTree node, Program program) {
    string funName = join(node.children[0].matches);
    Fun fun;
    switch (funName) {
        case "peek":
            fun = new PeekFun(node, program);
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

        default:
        assert(0);
    }

    return fun;
}

template FunConstructor()
{
    this(ParseTree node, Program program)
    {
        super(node, program);
        for(ubyte i=0; i<this.arg_count; i++) {
            auto e = this.node.children[1].children[i];
            this.arglist[i] = new Expression(e, this.program);
            this.arglist[i].eval();
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
    protected ubyte arg_count;
    protected Expression[8] arglist;
    protected string fncode;

    this(ParseTree node, Program program)
    {
        this.node = node;
        this.program = program;
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

    void process()
    {
        this.fncode ~= "\tpeek\n";
    }
}

class UsrFun:Fun
{
    // This function can take any number of parameters
    protected ubyte arg_count = 0;

    this(ParseTree node, Program program)
    {
        super(node, program);
        auto e_list = this.node.children[1].children;
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

    void process()
    {
        this.fncode ~= "\trnd\n";
    }
}

class InKeyFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 0;

    void process()
    {
        this.fncode ~= "\tinkey\n";
    }
}
