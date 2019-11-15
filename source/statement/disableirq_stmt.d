module statement.disableirq_stmt;

import std.string;
import pegged.grammar;
import language.statement;
import program;

class Disableirq_stmt: Stmt
{
    mixin StmtConstructor;

    void process()
    {
        this.program.program_segment ~= "\tsei\n";
    }
}
