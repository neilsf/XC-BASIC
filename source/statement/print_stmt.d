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
                    this.program.program_segment ~= to!string(Ex);
                    if(type == 's') {
                        this.program.program_segment ~= "\tstdlib_putstr\n";
                    }
                    else {
                        this.program.program_segment ~= "\tstdlib_print"~ to!string(type) ~"\n";
                    }
                break;

                case "XCBASIC.String":
                    string str = join(exlist.children[i].matches[1..$-1]);
                    Stringliteral sl = new Stringliteral(str, this.program);
                    sl.register();
                    this.program.program_segment ~= "\tpaddr _S" ~ to!string(Stringliteral.id) ~ "\n";
                    this.program.program_segment ~= "\tstdlib_putstr\n";
                break;
            }
        }

        this.program.program_segment ~= "\tlda #13\n";
        this.program.program_segment ~= "\tjsr KERNAL_PRINTCHR\n";
    }
}
