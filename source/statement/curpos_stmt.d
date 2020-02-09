module statement.curpos_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Curpos_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto e1 = this.node.children[0].children[0];
        auto xpos = new Expression(e1, this.program);
        xpos.eval();

        auto e2 = this.node.children[0].children[1];
        auto ypos = new Expression(e2, this.program);
        ypos.eval();

        if(xpos.type != 'b') {
            xpos.convert('b');
        }

        if(ypos.type != 'b') {
            ypos.convert('b');
        }

        this.program.appendProgramSegment(to!string(ypos));
        this.program.appendProgramSegment(to!string(xpos));
        this.program.appendProgramSegment("\tcurpos\n");

        this.program.use_stringlib = true;
    }
}
