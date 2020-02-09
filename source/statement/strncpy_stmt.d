module statement.strncpy_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Strncpy_stmt:Stmt
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
            this.program.error("STRNCPY accepts string pointers only");
        }

        auto e3 = this.node.children[0].children[2];
        auto Ex3 = new Expression(e3, this.program);
        Ex3.eval();

        if(Ex3.type != 'b') {
            Ex3.convert('b');
        }

        this.program.appendProgramSegment(to!string(Ex1));
        this.program.appendProgramSegment(to!string(Ex2));
        this.program.appendProgramSegment(to!string(Ex3));
        this.program.use_stringlib = true;
        this.program.appendProgramSegment("\tstrncpy\n");
    }
}
