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

        if(this.program.in_procedure) {
            asm_string = this.replace_special_keywords(asm_string);
        }

        this.program.appendProgramSegment("\t; Inline ASM start\n");
        this.program.appendProgramSegment(asm_string~"\n");
        this.program.appendProgramSegment("\t; Inline ASM end\n");
    }

    private string replace_special_keywords(string asm_string)
    {
        return asm_string.replace("{self}", "_" ~ this.program.current_proc_name);
    }
}
