module statement.endwhile_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.conv;

class Endwhile_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        int counter = this.program.while_stack.pull();
        this.program.program_segment ~= "\tjmp _WH_" ~ to!string(counter) ~ "\n";
        this.program.program_segment ~= "_EW_" ~ to!string(counter) ~ ":\n";
    }
}
