module statement.asm_stmt;

import std.string;
import pegged.grammar;
import language.statement;
import program;

class Asm_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string asm_string = stripLeft(chop(join(this.node.children[0].children[0].matches)), "\"");
        this.program.appendProgramSegment("\t; Inline ASM start\n");
        this.program.appendProgramSegment(asm_string~"\n");
        this.program.appendProgramSegment("\t; Inline ASM end\n");
    }
}
