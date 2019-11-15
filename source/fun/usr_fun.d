module fun.usr_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Usr_fun:Fun
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
