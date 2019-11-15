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

        if(indexOf("bw", xpos.type) == -1 || indexOf("bw", ypos.type) == -1) {
            this.program.error("CURPOS accepts arguments of type byte or int");
        }

        if(xpos.type == 'w') {
            xpos.convert('b');
        }

        if(ypos.type == 'w') {
            ypos.convert('b');
        }

        this.program.program_segment ~= to!string(ypos);
        this.program.program_segment ~= to!string(xpos);

        this.program.use_stringlib = true;
        this.program.program_segment~="\tcurpos\n";
    }
}
