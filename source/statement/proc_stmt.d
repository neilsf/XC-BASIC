module statement.proc_stmt;

import std.conv, std.string;
import pegged.grammar;
import language.statement;
import program;

class Proc_stmt:Stmt
{
    mixin StmtConstructor;

    string name;

    protected string get_variant()
    {
        return "Procedure";
    }

    private void verify_context()
    {
        if(this.program.in_procedure) {
            this.program.error(this.get_variant() ~ " definition is not allowed here.");
        }
        this.program.in_procedure = true;
    }

    protected void verify_name()
    {
        ParseTree pname = this.node.children[0].children[0];
        string name = join(pname.matches);
        if(this.program.procExists(name)) {
            this.program.error(this.get_variant() ~ " already defined");
        }

        this.program.current_proc_name = name;
        this.name = name;
    }

    private void add_arguments(ref Procedure proc)
    {
        Variable[] arguments;
        ubyte varlist_index = 2;
        if(this.get_variant() == "Procedure") {
            varlist_index = 1;
        }

        if(this.node.children[0].children.length > varlist_index) {
            ParseTree varlist = this.node.children[0].children[varlist_index];
            foreach(ref var; varlist.children) {
                Variable argument =
                    Variable(
                        0,
                        join(var.children[0].matches),
                        this.program.resolve_sigil(join(var.children[1].matches))
                    );
                this.program.addVariable(argument);
                proc.addArgument(argument);
            }
        }
    }

    protected Procedure get_procedure()
    {
        Procedure proc = Procedure(this.name);
        return proc;
    }

    void process()
    {
        this.verify_context();
        this.verify_name();

        Procedure proc = this.get_procedure();
        this.add_arguments(proc);

        this.program.procedures ~= proc;
        this.program.program_segment ~= "\tjmp " ~ proc.getLabel() ~ "_end\n";
        this.program.program_segment ~= proc.getLabel() ~ ":\n";
    }
}
