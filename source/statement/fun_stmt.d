module statement.fun_stmt;

import statement.proc_stmt;
import std.conv, std.string;
import pegged.grammar;
import language.statement;
import program;

class Fun_stmt : Proc_stmt
{
    mixin StmtConstructor;

    override protected string get_variant()
    {
        return "Function";
    }

    override protected Procedure get_procedure()
    {
        string sigil = this.node.children[0].children[1].matches[0];
        char type = this.program.resolve_sigil(sigil);
        Procedure proc = {name: this.name, is_function: true, type: type};
        return proc;
    }
}
