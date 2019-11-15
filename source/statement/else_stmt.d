module statement.else_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.conv;

class Else_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string label_q = to!string(this.program.if_stack.top());
        this.program.appendProgramSegment("\tjmp _EI_" ~label_q~ "\n");
        this.program.appendProgramSegment("_EL_"~ label_q ~ ":\n");
    }
}
