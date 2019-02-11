module fun;

import pegged.grammar;
import program;
import std.string, std.conv, std.stdio;
import expression;

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
    public char type = 'i';

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
    public char type = 'i';

    void process()
    {
        this.fncode ~= "\tpeek\n";
    }
}

class RndFun:Fun
{
    mixin FunConstructor;
    protected ubyte arg_count = 0;
    public char type = 'i';

    void process()
    {
        this.fncode ~= "\trnd\n";
    }
}

class InKeyFun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 0;
    public char type = 'i';

    void process()
    {
        this.fncode ~= "\tinkey\n";
    }
}
