module statement.endfun_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement;
import program;

class Endfun_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        if(!this.program.in_procedure) {
            this.program.error("Not in function context");
        }

        Procedure current_proc = this.program.findProcedure(this.program.current_proc_name);

        if(!current_proc.is_function) {
            this.program.error("Not in function context. Did you mean ENDPROC?");
        }

        this.program.appendProgramSegment("\tbrk\n"); // Should never reach here. It means no return statement was used.
        this.program.appendProgramSegment(current_proc.getLabel() ~"_tmp_retaddr DC.W 0\n");
        this.program.appendProgramSegment(current_proc.getLabel() ~"_end:\n");

        this.program.in_procedure = false;
        this.program.current_proc_name = "";
    }
}
