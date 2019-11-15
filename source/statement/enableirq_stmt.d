module statement.enableirq_stmt;

import std.string;
import pegged.grammar;
import language.statement;
import program;

class Enableirq_stmt: Stmt
{
    mixin StmtConstructor;

    void process()
    {
        this.program.program_segment ~= "\tcli\n";
    }
}
