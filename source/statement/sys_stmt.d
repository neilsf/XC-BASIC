module statement.sys_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Sys_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto e1 = this.node.children[0].children[0];

        auto Ex1 = new Expression(e1, this.program);
        Ex1.eval();

        this.program.appendProgramSegment(to!string(Ex1));
        this.program.appendProgramSegment("\tsys\n");
    }
}
