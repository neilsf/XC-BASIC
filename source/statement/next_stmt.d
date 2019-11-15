module statement.next_stmt;

import std.conv, std.string;

import pegged.grammar;

import language.statement;

import program;

class Next_stmt:Stmt
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
            this.program.error("Variable "~varname~" is a float");
        }

        this.program.program_segment ~= "\tnext"~to!string(var.type)~" "~var.getLabel()~"\n";
    }
}
