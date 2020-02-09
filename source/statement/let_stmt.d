module statement.let_stmt;

import language.statement;
import program;
import language.number;
import pegged.grammar;
import std.string, std.conv;
import language.expression;
import language.xcbarray;

class Let_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        ParseTree v = this.node.children[0].children[0];
        ParseTree ex = this.node.children[0].children[1];
        string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        char vartype = this.program.resolve_sigil(sigil);

        if(!this.program.is_variable(varname, sigil)) {
            this.program.addVariable(Variable(0, varname, vartype));
        }
        Variable var = this.program.findVariable(varname, sigil);
        if(var.isConst) {
            this.program.error("Can't assign value to a constant");
        }
        Expression Ex = new Expression(ex, this.program);

        char extype = Ex.detect_type();

        extype = (extype == 's' ? 'w' : extype);
        vartype = (vartype == 's' ? 'w' : vartype);

        if
        (
            (extype == 'f' && vartype != 'f') ||
            (vartype == 'f' && extype != 'f')
        ) {
            this.program.error("Type mismatch");
        }

        Ex.eval();

        if(extype != vartype) {
            Ex.convert(vartype);
        }

        this.program.appendProgramSegment(to!string(Ex));

        if(v.children.length > 2) {
            /* any variable can be accessed as an array
            if(var.dimensions[0] == 1 && var.dimensions[1] == 1) {
                this.program.error("Not an array");
            }
            */
            auto subscript = v.children[2];
            XCBArray arr = new XCBArray(this.program, var, subscript);
            this.program.appendProgramSegment(arr.store());
        }
        else {
            this.program.appendProgramSegment("\tpl" ~ to!string(vartype) ~ "2var " ~ var.getLabel() ~ "\n");
        }
    }
}
