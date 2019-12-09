module fun.userdef_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class UserDef_fun : Fun
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

        bool recursive = (this.proc.name == this.program.current_proc_name);

        for(ubyte i = 0; i < this.proc.arguments.length; i++) {
            asmcode ~= to!string(this.arglist[i]);
            char vartype = this.proc.arguments[i].type;
            string varlabel = this.proc.arguments[i].getLabel();
            asmcode ~= "\tpl" ~ to!string(vartype) ~ "2var " ~ varlabel ~ "\n";
        }

        if(recursive) {
            asmcode ~= this.program.push_locals();
        }

        asmcode ~= fncode;

        if(recursive) {
            asmcode ~= this.program.pull_locals();
        }

        return asmcode;
    }
}
