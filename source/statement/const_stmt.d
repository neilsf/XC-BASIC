module statement.const_stmt;

import language.statement;
import program;
import language.number;
import pegged.grammar;
import std.string;

class Const_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        ParseTree v = this.node.children[0].children[0];
        ParseTree num = this.node.children[0].children[1];
        string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        char vartype = this.program.resolve_sigil(sigil);

        if(vartype == 's') {
            this.program.error("A string pointer cannot be constant");
        }

        Number number = new Number(num, this.program);

        if
        (
            (number.type == 'f' && vartype != 'f') ||
            (vartype == 'f' && number.type != 'f')
        ) {
            this.program.error("Type mismatch");
        }

        if(vartype == 'b' && (number.intval < 0 || number.intval > 255)) {
            this.program.error("Number out of range");
        }

        Variable var = {
            name: varname,
            type: vartype,
            isConst: true,
            constValInt: number.intval,
            constValFloat: number.floatval
        };

        if(!this.program.is_variable(varname, sigil)) {
            this.program.addVariable(var);
        }
        else {
            this.program.error("A variable or constant already exists with that name");
        }
    }
}
