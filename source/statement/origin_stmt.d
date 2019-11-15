module statement.origin_stmt;

import std.string;
import pegged.grammar;
import language.statement;
import program;

class Origin_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string num = join(this.node.children[0].children[0].matches);
        this.program.appendProgramSegment("\torg "~num~"\n");
    }
}
