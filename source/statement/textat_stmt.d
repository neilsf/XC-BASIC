module statement.textat_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.string, std.conv;
import language.expression;
import language.stringliteral;

class Textat_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        ParseTree exlist = this.node.children[0];
        Expression col = new Expression(exlist.children[0], this.program);
        Expression row = new Expression(exlist.children[1], this.program);

        if(col.detect_type() == 'f' || row.detect_type == 'f') {
            this.program.error("Column and row must be bytes or integers");
        }

        col.eval();
        if(col.type == 'w') {
            col.convert('b');
        }
        row.eval();
        if(row.type == 'w') {
            row.convert('b');
        }

        string offset_code = "";

        offset_code ~= to!string(row);
        offset_code ~= to!string(col);

        if(exlist.children[2].name == "XCBASIC.Expression") {

            Expression ex = new Expression(exlist.children[2], this.program);
            ex.eval();

            if(ex.type != 's') {
                this.program.appendProgramSegment(offset_code);
                this.program.appendProgramSegment(to!string(ex) ~ "\n");
                this.program.appendProgramSegment("\t"~to!string(ex.type)~"at\n");
            }
            else {
                this.program.appendProgramSegment(to!string(ex) ~ "\n");
                this.program.appendProgramSegment(offset_code);
                this.program.appendProgramSegment("\tstringat\n");
            }

        }
        else {
            // string literal
            string str = join(exlist.children[2].matches[1..$-1]);
            Stringliteral sl = new Stringliteral(str, this.program);
            sl.register(false, true);
            // text first
            this.program.appendProgramSegment(offset_code);
            this.program.appendProgramSegment("\tpaddr _S" ~ to!string(Stringliteral.id) ~ "\n");
            this.program.appendProgramSegment("\ttextat\n");
        }
    }
}
