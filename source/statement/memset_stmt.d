module statement.memset_stmt;

import std.string, std.conv;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Memset_stmt: Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto args = this.node.children[0].children;
        auto source = new Expression(args[0], this.program);
        source.eval();
        if(source.type == 'f') {
            this.program.error("Argument #1 of MEMSET must not be a float");
        }
        else if(source.type != 'w') {
            source.convert('w');
        }

        auto len = new Expression(args[1], this.program);
        len.eval();
        if(len.type == 'f') {
            this.program.error("Argument #2 of MEMSET must not be a float");
        }
        else if(len.type != 'w') {
            len.convert('w');
        }

        auto val = new Expression(args[2], this.program);
        val.eval();
        if(val.type == 'f') {
            this.program.error("Argument #3 of MEMSET must not be a float");
        }
        else if(val.type != 'w') {
            val.convert('w');
        }

        this.program.appendProgramSegment(to!string(val));
        this.program.appendProgramSegment(to!string(len));
        this.program.appendProgramSegment(to!string(source));
        this.program.appendProgramSegment("\tmemset\n");

        this.program.use_memlib = true;
    }
}
