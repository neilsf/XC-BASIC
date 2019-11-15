module statement.for_stmt;

import std.conv, std.string;

import pegged.grammar;

import language.statement;
import language.expression;

import program;

class For_stmt: Stmt
{
    mixin StmtConstructor;

    void process()
    {
        /* step 1 initialize variable */
        ParseTree v = this.node.children[0].children[0];
        ParseTree ex = this.node.children[0].children[1];
        string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        char vartype = this.program.resolve_sigil(sigil);

        if(vartype == 'f') {
            this.program.error("Index must not be a float");
        }

        if(!this.program.is_variable(varname, sigil)) {
            this.program.addVariable(Variable(0, varname, vartype));
        }
        Variable var = this.program.findVariable(varname, sigil);
        Expression Ex = new Expression(ex, this.program);
        Ex.eval();
        if(Ex.type == 'f' || (Ex.type == 'w' && vartype == 'b')) {
            this.program.error("Type mismatch");
        }
        else if(Ex.type == 'b' && vartype == 'w') {
            Ex.btow();
        }
        this.program.appendProgramSegment(to!string(Ex));
        this.program.appendProgramSegment("\tpl" ~ to!string(vartype) ~ "2var " ~ var.getLabel() ~ "\n");

        /* step 2 evaluate max_value and push value */
        ParseTree ex2 = this.node.children[0].children[2];
        Expression Ex2 = new Expression(ex2, this.program);
        Ex2.eval();
        if(Ex2.type == 'f' || (Ex2.type == 'w' && vartype == 'b')) {
            this.program.error("Type mismatch");
        }
        else if(Ex2.type == 'b' && vartype == 'w') {
            Ex2.btow();
        }
        this.program.appendProgramSegment(to!string(Ex2));

        /* step 3 call for */
        this.program.appendProgramSegment("\tfor\n");
    }
}
