module statement.goto_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.string;

class Goto_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string lbl = join(this.node.children[0].children[0].matches);
        if(!this.program.labelExists(lbl)) {
            this.program.error("Label "~lbl~" does not exist");
        }

        lbl = this.program.in_procedure ? this.program.current_proc_name ~ "." ~ lbl : lbl;
        this.program.program_segment ~= "\tjmp _L"~lbl~"\n";
    }
}
