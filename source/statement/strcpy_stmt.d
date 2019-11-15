module statement.strcpy_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Strcpy_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto e1 = this.node.children[0].children[0];
        auto Ex1 = new Expression(e1, this.program);
        Ex1.eval();

        auto e2 = this.node.children[0].children[1];
        auto Ex2 = new Expression(e2, this.program);
        Ex2.eval();

        if(Ex1.type != 's' || Ex2.type != 's') {
            this.program.error("STRCPY accepts string pointers only");
        }

        this.program.program_segment ~= to!string(Ex1);
        this.program.program_segment ~= to!string(Ex2);
        this.program.use_stringlib = true;
        this.program.program_segment~="\tstrcpy\n";
    }
}
