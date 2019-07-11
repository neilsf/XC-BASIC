module condition;

import pegged.grammar;
import program;
import expression;
import std.array, std.string, std.conv, std.stdio;

class Condition
{
    ParseTree node;
    Program program;
    string asmcode = "";

    this(ParseTree node, Program program)
    {
        this.node = node;
        this.program = program;
    }

    void eval()
    {
        ParseTree[] relations;
        int rel_count = 1;
        bool logop_present = false;

        relations ~= this.node.children[0];

        if(this.node.children.length > 1 && this.node.children[1].name == "XCBASIC.Logop") {
            relations ~= this.node.children[2];
            rel_count++;
            logop_present = true;
        }

        for(int i; i < rel_count; i++) {
            auto e1 = relations[i].children[0];
            string rel = join(relations[i].children[1].matches);
            auto e2 = relations[i].children[2];

            auto Ex1 = new Expression(e1, this.program);
            Ex1.eval();
            auto Ex2 = new Expression(e2, this.program);
            Ex2.eval();

            string exp_type;

            if(Ex1.detect_type() == Ex2.detect_type()) {
                exp_type = to!string(Ex1.type);
            }
            else {
                char common_type = this.program.get_higher_type(Ex1.type, Ex2.type);
                if(Ex1.type != common_type) {
                    Ex1.convert(common_type);
                }
                else {
                    Ex2.convert(common_type);
                }
                exp_type = to!string(common_type);
            }

            this.asmcode ~= to!string(Ex1);
            this.asmcode ~= to!string(Ex2);

            string rel_type;

            final switch(rel) {
                case "<":
                    rel_type = "lt";
                    break;

                case "<=":
                    rel_type = "lte";
                    break;

                case "<>":
                    rel_type = "neq";
                    break;

                case ">":
                    rel_type = "gt";
                    break;

                case ">=":
                    rel_type = "gte";
                    break;

                case "=":
                    rel_type = "eq";
                    break;
            }

            exp_type = (exp_type == "s" ? "w" : exp_type);
            this.asmcode~="\tcmp" ~ exp_type ~rel_type~"\n";
        }

        // relations are evaluated, now the comes logical op if present

        if(logop_present) {
            string logop = join(this.node.children[1].matches);
            final switch(logop) {
                case "and":
                    this.asmcode~="\tandb\n";
                break;

                case "or":
                    this.asmcode~="\torb\n";
                break;
            }
        }
    }
}
