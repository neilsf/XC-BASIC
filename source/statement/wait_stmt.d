module statement.wait_stmt;

import std.string, std.conv;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Wait_stmt: Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto args = this.node.children[0].children;
        auto address = new Expression(args[0], this.program);
        address.eval();
        if(address.type == 'f') {
            this.program.error("Argument #1 of WAIT must not be a float");
        }
        else if(address.type != 'w') {
            address.convert('w');
        }

        auto mask = new Expression(args[1], this.program);
        mask.eval();
        if(mask.type == 'f') {
            this.program.error("Argument #2 of WAIT must not be a float");
        }
        else if(mask.type != 'b') {
            mask.convert('b');
        }

        if(args.length > 2) {
            auto trig = new Expression(args[2], this.program);
            trig.eval();
            if(trig.type == 'f') {
                this.program.error("Argument #3 of WAIT must not be a float");
            }
            else if(trig.type != 'b') {
                trig.convert('b');
            }
            this.program.appendProgramSegment(to!string(trig));
        }
        else {
            this.program.appendProgramSegment("\tpzero\n");
        }

        this.program.appendProgramSegment(to!string(mask));
        this.program.appendProgramSegment(to!string(address));
        this.program.appendProgramSegment("\twait\n");
    }
}
