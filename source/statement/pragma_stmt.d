module statement.pragma_stmt;

import std.string, std.conv;
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
        string option_val = "";
        if(stmt.children[1].name == "XCBASIC.Number") {
            auto num = new Number(stmt.children[1], this.program);
            option_val = to!string(num.intval);
        }
        else {
            option_val = join(stmt.children[1].matches[1..$-1]);
        }

        this.program.setCompilerOption(option_key, option_val);
    }
}
