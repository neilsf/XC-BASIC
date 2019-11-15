module statement.return_fn_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Return_fn_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        if(!this.program.in_procedure) {
            this.program.error("Not in function context");
        }

        Procedure current_proc = this.program.findProcedure(this.program.current_proc_name);

        if(!current_proc.is_function) {
            this.program.error("Procedures can't return a value.");
        }

        auto e1 = this.node.children[0].children[0];
        auto Ex1 = new Expression(e1, this.program);
        Ex1.eval();

        if(Ex1.type != current_proc.type) {
            this.program.error("Function " ~ current_proc.name ~ " is supposed to return a(n) " ~
                this.program.vartype_names[current_proc.type] ~ ", not a(n) " ~
                this.program.vartype_names[Ex1.type]);
        }

        this.program.appendProgramSegment("\tpull_retaddr "~ current_proc.getLabel() ~"\n");
        this.program.appendProgramSegment(to!string(Ex1));
        this.program.appendProgramSegment("\tpush_retaddr "~ current_proc.getLabel() ~"\n");
        this.program.appendProgramSegment("\trts\n");
    }
}
