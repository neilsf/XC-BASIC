module statement.save_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement, language.expression, language.stringliteral;
import program;

class Save_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string filename = join(this.node.children[0].children[0].matches)[1..$-1];
        if(filename == "") {
            this.program.error("Empty string");
        }

        auto sl = new Stringliteral(filename, this.program);
        sl.register();

        auto device_no = new Expression(this.node.children[0].children[1], this.program);
        device_no.eval();
        if(device_no.type == 'f') {
            this.program.error("Argument #2 of SAVE must not be a float");
        }
        else if(device_no.type == 'b') {
            device_no.btow();
        }

        auto address1 = new Expression(this.node.children[0].children[2], this.program);
        address1.eval();
        if(address1.type != 'w') {
            this.program.error("Argument #3 of SAVE must be an integer");
        }

        auto address2 = new Expression(this.node.children[0].children[3], this.program);
        address2.eval();
        if(address2.type != 'w') {
            this.program.error("Argument #4 of SAVE must be an integer");
        }

        this.program.appendProgramSegment(to!string(address2));
        this.program.appendProgramSegment(to!string(address1));
        this.program.appendProgramSegment(to!string(device_no));
        this.program.appendProgramSegment("\tpbyte #" ~ to!string(filename.length) ~ "\n");
        this.program.appendProgramSegment("\tlda #<_S" ~ to!string(Stringliteral.id) ~ "\n");
        this.program.appendProgramSegment("\tpha\n");
        this.program.appendProgramSegment("\tlda #>_S" ~ to!string(Stringliteral.id) ~ "\n");
        this.program.appendProgramSegment("\tpha\n");
        this.program.appendProgramSegment("\tsave\n");
    }
}
