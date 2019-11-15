module statement.watch_stmt;

import std.string, std.conv;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Watch_stmt: Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto args = this.node.children[0].children;
        auto address = new Expression(args[0], this.program);
        bool const_addr = address.is_const();
        address.eval();
        if(address.type == 'f') {
            this.program.error("Argument #1 of WATCH must not be a float");
        }
        else if(address.type == 'b') {
            address.convert('w');
        }

        auto mask = new Expression(args[1], this.program);
        mask.eval();
        if(mask.type == 'f') {
            this.program.error("Argument #2 of WATCH must not be a float");
        }
        else if(mask.type == 'w') {
            mask.convert('b');
        }

        this.program.program_segment ~= to!string(mask);
        if(!const_addr) {
            this.program.program_segment ~= to!string(address);
            this.program.program_segment ~= "\twatch\n";
        }
        else {
            this.program.program_segment ~= "\twatchc "~ to!string(address.get_constval()) ~"\n";
        }

    }
}
