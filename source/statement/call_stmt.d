module statement.call_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.string, std.conv, std.algorithm.mutation;
import language.expression;

class Call_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        bool is_cmd = (node.children[0].name == "XCBASIC.Userdef_cmd");
        string lbl = join(this.node.children[0].children[0].matches);

        if(!this.program.procExists(lbl)) {
            string error;
            if(is_cmd) {
                error = "Unknown command: " ~ lbl;
            }
            else {
                error = "Unknown procedure: " ~ lbl;
            }
            this.program.error(error);
        }
        Procedure proc = this.program.findProcedure(lbl);
        if(this.node.children[0].children.length > 1) {
            ParseTree exprlist = this.node.children[0].children[1];
            if(exprlist.children.length != proc.arguments.length) {
                this.program.error("Wrong number of arguments");
            }

            for(ubyte i = 0; i < proc.arguments.length; i++) {
                Expression Ex = new Expression(exprlist.children[i], this.program);
                Ex.eval;
                if(proc.arguments[i].type != Ex.detect_type()) {
                    Ex.convert(proc.arguments[i].type);
                }
                this.program.appendProgramSegment(to!string(Ex));
                char vartype = proc.arguments[i].type;
                string varlabel = proc.arguments[i].getLabel();
                this.program.appendProgramSegment("\tpl" ~ to!string(vartype) ~ "2var " ~ varlabel ~ "\n");
            }
        }

        bool recursive = false;
        if(lbl == this.program.current_proc_name) {
            recursive = true;
            this.program.appendProgramSegment(this.program.push_locals());
        }

        this.program.appendProgramSegment("\tjsr " ~ proc.getLabel() ~ "\n");

        if(recursive) {
            this.program.appendProgramSegment(this.program.pull_locals());
        }
    }
}
