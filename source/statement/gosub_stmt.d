module statement.gosub_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.string;

class Gosub_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string lbl = join(this.node.children[0].children[0].matches);
        if(!this.program.labelExists(lbl)) {
            this.program.error("Label "~lbl~" does not exist");
        }

        lbl = this.program.in_procedure ? this.program.current_proc_name ~ "." ~ lbl : lbl;
        this.program.appendProgramSegment("\tjsr _L"~lbl~"\n");
    }
}
