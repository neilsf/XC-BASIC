module statement.load_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement, language.expression, language.stringliteral;
import program;

class Load_stmt:Stmt
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
            this.program.error("Argument #2 of LOAD must not be a float");
        }
        else if(device_no.type == 'b') {
            device_no.btow();
        }

        bool fixed_address = false;
        if(this.node.children[0].children.length > 2) {
            auto address = new Expression(this.node.children[0].children[2], this.program);
            address.eval();
            if(address.type == 'f') {
                this.program.error("Argument #3 of LOAD must not be a float");
            }
            if(address.type != 'w') {
                address.convert('w');
            }
            this.program.appendProgramSegment(to!string(address));
            fixed_address = true;
        }

        this.program.appendProgramSegment(to!string(device_no));
        this.program.appendProgramSegment("\tpbyte #" ~ to!string(filename.length) ~ "\n");
        this.program.appendProgramSegment("\tlda #<_S" ~ to!string(Stringliteral.id) ~ "\n");
        this.program.appendProgramSegment("\tpha\n");
        this.program.appendProgramSegment("\tlda #>_S" ~ to!string(Stringliteral.id) ~ "\n");
        this.program.appendProgramSegment("\tpha\n");
        this.program.appendProgramSegment("\tload " ~ (fixed_address ? "0" : "1") ~ "\n");
    }
}
