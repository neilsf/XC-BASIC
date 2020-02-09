module statement.doke_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.string, std.conv;
import language.expression;

class Doke_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto e1 = this.node.children[0].children[0];
        auto e2 = this.node.children[0].children[1];

        auto Ex1 = new Expression(e1, this.program);
        if(Ex1.detect_type() != 'w') {
            this.program.error("Address must be an integer");
        }
        Ex1.eval();
        auto Ex2 = new Expression(e2, this.program);
        if(Ex2.detect_type() == 'f') {
            this.program.error("Value must not be a float");
        }

        Ex2.eval();
        if(Ex2.type != 'w') {
            Ex2.convert('w');
        }

        this.program.appendProgramSegment(to!string(Ex2)); // value first
        this.program.appendProgramSegment(to!string(Ex1)); // address last
        this.program.appendProgramSegment("\tdoke\n");
    }
}
