module language.term;

import pegged.grammar;
import program;
import language.factor;
import std.conv;
import std.stdio;
import std.string;
import core.stdc.stdlib;

class Term
{
    ParseTree node;
    Program program;
    string asmcode;
    char expected_type;

    this(ParseTree node, Program program)
    {
        this.node = node;
        this.program = program;
    }

    bool is_const()
    {
        if(this.node.children.length > 1) {
            return false;
        }

        Factor tmpFact = new Factor(this.node.children[0], this.program);
        return tmpFact.is_const();
    }

    char detect_type()
    {
        Factor tmpFact;
        char tmptype = 'b';
        long current_pos = 0;
        foreach(ref child; this.node.children) {
            if(child.name == "XCBASIC.Factor") {
                tmpFact = new Factor(child, this.program);
                char tmpFactType = tmpFact.detect_type();
                long pos = this.program.type_precedence.indexOf(tmpFactType);
                if(pos > current_pos) {
                    tmptype = tmpFactType;
                    current_pos = pos;
                }
            }
        }
        return tmptype;
    }

    void eval()
    {
        char i = 0;
    	Factor f1 = new Factor(this.node.children[i], this.program);
        f1.expected_type = this.expected_type;
        f1.eval();
        this.asmcode ~= to!string(f1);
        if(this.node.children.length > 1) {
            for(i = 1; i < this.node.children.length; i += 2) {
                string t_op = this.node.children[i].matches[0];
                Factor f = new Factor(this.node.children[i+1], this.program);
                f.expected_type = this.expected_type;
                f.eval();
                this.asmcode ~= to!string(f);
                string type = to!string(this.expected_type == 's' ? 'w' : this.expected_type);
                final switch(t_op) {
                    case "*":
                        this.asmcode ~= "\tmul"~type~"\n";
                    break;

                    case "/":
                        this.asmcode ~= "\tdiv"~type~"\n";
                    break;
                }
            }
        }
    }

    override string toString()
    {
        return this.asmcode;
    }
}
