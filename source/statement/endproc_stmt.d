module statement.endproc_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement;
import program;

class Endproc_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        if(!this.program.in_procedure) {
            this.program.error("Not in procedure context");
        }

        Procedure current_proc = this.program.findProcedure(this.program.current_proc_name);

        if(current_proc.is_function) {
            this.program.error("Not in procedure context. Did you mean ENDFUN?");
        }

        this.program.appendProgramSegment("\trts\n");
        this.program.appendProgramSegment(current_proc.getLabel() ~"_end:\n");

        this.program.in_procedure = false;
        this.program.current_proc_name = "";
    }
}
