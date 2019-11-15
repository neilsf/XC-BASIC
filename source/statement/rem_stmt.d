module statement.rem_stmt;

import language.statement;
import program;
import pegged.grammar;

class Rem_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        {}
    }
}
