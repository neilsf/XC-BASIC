module statement.inc_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement, language.xcbarray;
import program;

class Inc_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        ParseTree v = this.node.children[0].children[0];
        string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        if(!this.program.is_variable(varname, sigil)) {
            this.program.error("Variable " ~varname~" does not exist");
        }

        Variable var = this.program.findVariable(varname, sigil);

        if(var.type == 'f') {
            this.program.error("INC does not work on floats");
        }

        if(var.isConst) {
            this.program.error(varname ~ " is a constant");
        }

        string asmcode;

        if(v.children.length > 2) {
            // an array
            auto subscript = v.children[2];
            XCBArray arr = new XCBArray(this.program, var, subscript);
            asmcode = arr.incordec("inc");
        }
        else {
            asmcode = "\tinc"~to!string(var.type)~" "~var.getLabel()~"\n";
        }

        this.program.program_segment ~= asmcode;
    }
}
