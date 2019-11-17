module statement.dim_stmt;

import program;
import language.statement;
import language.number;
import language.expression;
import pegged.grammar;
import std.string, std.conv;

class Dim_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        ParseTree v = this.node.children[0].children[0];
        bool is_fast = false;
        if(this.node.matches[$-1] == "fast" || this.node.matches[$-1] == "FAST") {
            is_fast = true;
        }

        string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        char vartype = this.program.resolve_sigil(sigil);

        ushort[2] dimensions;
        if(v.children.length > 2) {
            auto subscript = v.children[2];

            ubyte i = 0;
            foreach(ref expr; subscript.children) {
                string dim = join(expr.matches);
                int dimlen = 0;

                // Case 1: test for constant
                if(this.program.is_variable(dim, "")) {
                    Variable var = this.program.findVariable(dim, "");
                    if(!var.isConst) {
                        this.program.error("Only numeric constants are accepted as array dimensions");
                    }
                    if(var.type != 'w') {
                        this.program.error("Array dimensions must be integers");
                    }

                    dimlen = var.constValInt;
                }
                // Case 2: test for numeric literal
                else {
                    if(expr.children.length > 1) {
                        this.program.error("Only numeric constants are accepted as array dimensions");
                    }
                    Number num = new Number(expr.children[0].children[0].children[0].children[0], this.program);
                    if(num.type == 'f') {
                        this.program.error("Array dimensions must be integers");
                    }
                    dimlen = num.intval;
                }

                dimensions[i] = to!ushort(dimlen);
                i++;
            }

            if(dimensions[1] == 0) {
                dimensions[1] = 1;
            }
        }
        else {
            dimensions[0]=1;
            dimensions[1]=1;
        }

        if(this.program.is_variable(varname, sigil)) {
            this.program.error("Variable "~varname~" is already defined/used.");
        }

        ushort addr = 0;

        if(this.node.children[0].children.length > 1) {
            Expression e = new Expression(this.node.children[0].children[1], this.program);
            e.eval();
            if(!e.is_const()) {
                this.program.error("Variable address must be a constant");
            }

            if(e.type != 'w') {
                this.program.error("Variable address must be an integer, got " ~ this.program.vartype_names[e.type]);
            }

            if(is_fast) {
                this.program.error("Can't use FAST together with @");
            }

            addr = to!ushort(e.get_constval());
        }

        Variable var = Variable(addr, varname, vartype, dimensions);
        if(addr > 0) {
            var.isExplicitAddr = true;
        }
        this.program.addVariable(var, is_fast);
    }
}
