module statement.input_stmt;

import std.conv, std.string;

import pegged.grammar;

import language.statement;
import language.expression;
import language.stringliteral;

import program;

class Input_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        this.program.use_stringlib = true;
        ParseTree list = this.node.children[0];

        ParseTree v = list.children[0];
        string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        char vartype = this.program.resolve_sigil(sigil);
        if(!this.program.is_variable(varname, sigil)) {
            this.program.error("Variable does not exist");
        }
        Variable var = this.program.findVariable(varname, sigil);
        if(vartype != 's') {
            this.program.error("Argument 1 of INPUT must be a string pointer");
        }

        this.program.program_segment ~= "\tpwvar "~var.getLabel()~"\n";

        ParseTree len = list.children[1];
        Expression e = new Expression(len, this.program);
        if(e.detect_type() != 'b') {
            this.program.error("Argument 2 of INPUT must be a byte");
        }

        e.eval();
        this.program.program_segment ~= e.asmcode;

        if(list.children.length > 2) {
            string mask = join(list.children[2].matches)[1..$-1];
            if(mask == "") {
                this.program.error("Empty string");
            }

            auto sl = new Stringliteral(mask, this.program);
            sl.register();
            this.program.program_segment ~= "\tpaddr _S" ~ to!string(Stringliteral.id) ~ "\n";
        }
        else {
            this.program.program_segment ~= "\tpaddr str_default_mask\n";
        }

        this.program.program_segment~="\tinput\n";
    }
}
