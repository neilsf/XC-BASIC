module statement.repeat_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.conv;

class Repeat_stmt:Stmt
{
    mixin StmtConstructor;

    public static int counter = 0;

    void process()
    {
        counter++;
        this.program.repeat_stack.push(counter);
        this.program.program_segment ~= "_RP_" ~ to!string(counter) ~ ":\n";
    }
}
