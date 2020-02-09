module statement.for_stmt;

import std.conv, std.string;

import pegged.grammar;

import language.statement;
import language.expression;

import program;

class For_stmt: Stmt
{
    mixin StmtConstructor;

    public static int counter = 0;

    public static Variable[int] save_var;

    void process()
    {
        counter++;
        this.program.for_stack.push(counter);

        string ret;
        string strcounter = to!string(counter);

        /* step 1 initialize variable */
        ParseTree v = this.node.children[0].children[0];
        ParseTree ex = this.node.children[0].children[1];
        string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        char vartype = this.program.resolve_sigil(sigil);

        if(vartype == 'f') {
            this.program.error("Counter must not be a float");
        }

        if(!this.program.is_variable(varname, sigil)) {
            this.program.addVariable(Variable(0, varname, vartype));
        }

        Variable var = this.program.findVariable(varname, sigil);
        Expression Ex = new Expression(ex, this.program);
        Ex.eval();
        if(Ex.type != vartype) {
            Ex.convert(vartype);
        }
        this.program.appendProgramSegment(to!string(Ex));
        this.program.appendProgramSegment("\tpl" ~ to!string(vartype) ~ "2var " ~ var.getLabel() ~ "\n");

        save_var[counter] = var;

        /* evaluate max_value and save to private variable */
        ParseTree ex2 = this.node.children[0].children[2];
        Expression Ex2 = new Expression(ex2, this.program);
        Ex2.eval();
        if(Ex2.type == 'f') {
             this.program.error("Limit must not be a float");
        }
        else if(Ex2.type != vartype) {
            Ex2.convert(vartype);
        }

        Variable max_var = Variable(0, "FOR_max_" ~ to!string(counter), vartype);
        max_var.isPrivate = true;
        this.program.addVariable(max_var);
        this.program.appendProgramSegment(to!string(Ex2));
        this.program.appendProgramSegment("\tpl" ~ vartype ~ "2var " ~ max_var.getLabel() ~ "\n");

        // is there a STEP keyword?
        if(this.node.children[0].children.length > 3) {
            ParseTree ex3 = this.node.children[0].children[3];
            Expression Ex3 = new Expression(ex3, this.program);
            Ex3.eval();
            if(Ex3.type == 'f') {
                this.program.error("Step must not be a float");
            }
            else if(Ex3.type != vartype) {
                Ex3.convert(vartype);
            }

            Variable step_var = Variable(0, "FOR_step_" ~ to!string(counter), vartype);
            step_var.isPrivate = true;
            this.program.addVariable(step_var);
            this.program.appendProgramSegment(to!string(Ex3));
            this.program.appendProgramSegment("\tpl" ~ vartype ~ "2var " ~ step_var.getLabel() ~ "\n");
        }

        this.program.appendProgramSegment("_FOR_" ~ to!string(counter) ~ ":\n");
    }
}
