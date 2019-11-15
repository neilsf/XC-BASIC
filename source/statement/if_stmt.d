module statement.if_stmt;

import language.statement;
import program;
import language.number;
import pegged.grammar;
import std.string, std.conv;
import language.condition;

class If_stmt:Stmt
{
    mixin StmtConstructor;

    public static int counter = 65536;

    void process()
    {
        auto statement = this.node.children[0];
        Condition cond = new Condition(statement.children[0], this.program);
        cond.eval();
        this.program.appendProgramSegment(cond.asmcode);

        int cursor = 1;
        auto st = statement.children[cursor];
        bool else_present = false;

        ParseTree else_st;

        if(statement.children.length > cursor + 1) {
            else_present = true;
            else_st = statement.children[cursor + 1];
        }

        string ret;
        ret ~= "\tcond_stmt _EI_" ~ to!string(counter) ~ ", _EL_" ~ to!string(counter) ~ "\n";

        this.program.appendProgramSegment(ret);

        // can be multiple statements
        foreach(ref child; st.children) {
            Stmt stmt = StmtFactory(child, this.program);
            stmt.process();
        }

        // else branch
        if(else_present) {
            this.program.appendProgramSegment("\tjmp _EI_" ~ to!string(counter)  ~ "\n");
            this.program.appendProgramSegment("_EL_" ~to!string(counter)~ ":\n");

            // can be multiple statements
            foreach(ref e_child; else_st.children) {
                Stmt else_stmt = StmtFactory(e_child, this.program);
                else_stmt.process();
            }
        }

        this.program.appendProgramSegment("_EI_" ~to!string(counter)~ ":\n");
        counter++;
    }
}

class If_standalone_stmt:Stmt
{
    mixin StmtConstructor;

    public static int counter = 0;

    void process()
    {
        counter++;
        this.program.if_stack.push(counter);

        auto statement = this.node.children[0];
        Condition cond = new Condition(statement.children[0], this.program);
        cond.eval();
        this.program.appendProgramSegment(cond.asmcode);
        this.program.appendProgramSegment("\tcond_stmt _EI_" ~ to!string(counter) ~ ", _EL_" ~ to!string(counter) ~ "\n");
    }
}
