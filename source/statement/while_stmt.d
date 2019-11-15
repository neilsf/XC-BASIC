module statement.while_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.conv;
import language.condition;

class While_stmt:Stmt
{
    mixin StmtConstructor;

    public static int counter = 0;

    void process()
    {
        counter++;
        this.program.while_stack.push(counter);

        string ret;
        string strcounter = to!string(counter);

        ret ~= "_WH_" ~ strcounter ~ ":\n";

        auto statement = this.node.children[0];
        Condition cond = new Condition(statement.children[0], this.program);
        cond.eval();
        ret ~= cond.asmcode;

        ret ~= "\tcond_stmt _EW_" ~ strcounter ~ ", _void_\n";
        this.program.program_segment ~= ret;
    }
}
