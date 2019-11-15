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
                this.program.program_segment ~= to!string(Ex);
                char vartype = proc.arguments[i].type;
                string varlabel = proc.arguments[i].getLabel();
                this.program.program_segment ~= "\tpl" ~ to!string(vartype) ~ "2var " ~ varlabel ~ "\n";
            }
        }

        bool recursive = false;
        if(lbl == this.program.current_proc_name) {
            recursive = true;
            // push local vars
            foreach(ref var; this.program.localVariables()) {
                if(var.dimensions == [1,1]) {
                    this.program.program_segment ~= "\tp"~to!string(var.type)~"var " ~ var.getLabel() ~ "\n";
                }
                else {
                    // an array
                    int length = var.dimensions[0] * var.dimensions[1] * this.program.varlen[var.type];
                    for(int offset = 0; offset < length; offset++) {
                        this.program.program_segment ~= "\tpbyte " ~ var.getLabel() ~ "+" ~to!string(offset)~ "\n";
                    }
                }
            }
        }

        this.program.program_segment ~= "\tjsr " ~ proc.getLabel() ~ "\n";

        if(recursive) {
            // pull local vars
            foreach(ref var; this.program.localVariables().reverse) {
                if(var.dimensions == [1,1]) {
                    this.program.program_segment ~= "\tpl"~to!string(var.type)~"2var " ~ var.getLabel() ~ "\n";
                }
                else {
                    // an array
                    int length = var.dimensions[0] * var.dimensions[1] * this.program.varlen[var.type];
                    for(int offset = length -1 ; offset >= 0; offset--) {
                        this.program.program_segment ~= "\tplb2var " ~ var.getLabel() ~ "+" ~to!string(offset)~ "\n";
                    }
                }

            }
        }
    }
}
