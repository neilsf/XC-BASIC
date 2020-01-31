module statement.next_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement;
import program;
import statement.for_stmt;

class Next_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        // get last for
        int counter = this.program.for_stack.pull();
        // get index var
        Variable index_var = For_stmt.save_var[counter];

        if(this.node.children[0].children.length > 0) {
            ParseTree v = this.node.children[0].children[0];
            string varname = join(v.children[0].matches);
            string sigil = join(v.children[1].matches);
            if(!this.program.is_variable(varname, sigil)) {
                this.program.error("Variable " ~varname~" does not exist");
            }

            Variable next_var = this.program.findVariable(varname, sigil);

            if(index_var.getLabel() != next_var.getLabel()) {
                this.program.error("Invalid variable name in NEXT statement. Expected: " ~ index_var.name ~ " or empty");
            }
        }
        // push index var's current value
        this.program.appendProgramSegment("\tnext"~to!string(index_var.type)~" "~to!string(counter)~", "~index_var.getLabel()~"\n");
    }
}
