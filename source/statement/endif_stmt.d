module statement.endif_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.conv;

class Endif_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        this.program.appendProgramSegment("_EI_"~ to!string(this.program.if_stack.pull()) ~ ":\n");
    }
}
