module statement.until_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.conv;
import language.condition;

class Until_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        int counter = this.program.repeat_stack.pull();

        string ret;
        string strcounter = to!string(counter);

        auto statement = this.node.children[0];
        Condition cond = new Condition(statement.children[0], this.program);
        cond.eval();
        ret ~= cond.asmcode;

        ret ~= "\tcond_stmt _RP_" ~ strcounter ~ ", _void_ \n";
        this.program.program_segment ~= ret;
    }
}
