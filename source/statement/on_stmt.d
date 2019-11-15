module statement.on_stmt;

import std.string, std.conv;
import pegged.grammar;
import language.statement, language.expression;
import program;

class On_stmt:Stmt
{
    mixin StmtConstructor;

    private static int counter = 0;

    void process()
    {
        On_stmt.counter++;
        auto args = this.node.children[0].children;
        auto e1 = args[0];
        auto index = new Expression(e1, this.program);
        index.eval();

        if(indexOf("bw", index.type) == -1 || indexOf("bw", index.type) == -1) {
            this.program.error("ON accepts argument of type byte or int");
        }

        if(index.type == 'w') {
            index.convert('b');
        }

        string branch_type = join(args[1].matches);
        string lbs ="_On_LB"~to!string(On_stmt.counter)~": DC.B ";
        string hbs ="_On_HB"~to!string(On_stmt.counter)~": DC.B ";
        for(int i=2; i < args.length; i++) {
            string lbl = join(args[i].matches);
            if(!this.program.labelExists(lbl)) {
                this.program.error("Label "~lbl~" does not exist");
            }

            lbl = "_L" ~ (this.program.in_procedure ? this.program.current_proc_name ~ "." ~ lbl : lbl);
            string comma = (i < args.length - 1 ? ", " : "");
            lbs~="<"~lbl~ comma;
            hbs~=">"~lbl~ comma;
        }

        this.program.data_segment ~= lbs ~ "\n" ~ hbs ~ "\n";
        this.program.appendProgramSegment(to!string(index));
        this.program.appendProgramSegment("\ton" ~ branch_type ~ " _On_LB"~to!string(On_stmt.counter)~", _On_HB"~to!string(On_stmt.counter) ~ "\n");
    }
}
