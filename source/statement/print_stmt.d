module statement.print_stmt;

import language.statement;
import program;
import pegged.grammar;
import std.string, std.conv;
import language.expression;
import language.stringliteral;

class Print_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        ParseTree exlist = this.node.children[0].children[0];
        for(char i=0; i< exlist.children.length; i++) {
            final switch(exlist.children[i].name) {

                case "XCBASIC.Expression":
                    auto Ex = new Expression(exlist.children[i], this.program);
                    Ex.eval();
                    char type = Ex.detect_type();
                    this.program.appendProgramSegment(to!string(Ex));
                    if(type == 's') {
                        this.program.appendProgramSegment("\tstdlib_putstr\n");
                    }
                    else {
                        this.program.appendProgramSegment("\tstdlib_print"~ to!string(type) ~"\n");
                    }
                break;

                case "XCBASIC.String":
                    string str = join(exlist.children[i].matches[1..$-1]);
                    Stringliteral sl = new Stringliteral(str, this.program);
                    sl.register();
                    this.program.appendProgramSegment("\tpaddr _S" ~ to!string(Stringliteral.id) ~ "\n");
                    this.program.appendProgramSegment("\tstdlib_putstr\n");
                break;
            }
        }

        this.program.appendProgramSegment("\tlda #13\n");
        this.program.appendProgramSegment("\tjsr KERNAL_PRINTCHR\n");
    }
}
