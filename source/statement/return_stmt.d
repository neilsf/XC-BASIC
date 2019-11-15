module statement.return_stmt;

import language.statement;
import program;
import pegged.grammar;

class Return_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        this.program.program_segment ~= "\trts\n";
    }
}
