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
        this.program.program_segment ~= "\tjmp _EI_" ~label_q~ "\n";
        this.program.program_segment ~= "_EL_"~ label_q ~ ":\n";
    }
}
