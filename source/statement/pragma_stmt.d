module statement.pragma_stmt;

import std.string;
import pegged.grammar;
import language.statement, language.number;
import program;

class Pragma_stmt: Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto stmt = this.node.children[0];
        string option_key = join(stmt.children[0].matches);
        auto num = new Number(stmt.children[1], this.program);
        this.program.setCompilerOption(option_key, num.intval);
    }
}
