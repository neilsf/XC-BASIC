module statement.end_stmt;

import language.statement;
import program;
import pegged.grammar;

class End_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        this.program.appendProgramSegment("\thalt\n");
    }
}
