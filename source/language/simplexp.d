module language.simplexp;

import pegged.grammar;
import program;
import language.term;
import std.conv;
import std.stdio;
import std.string;
import core.stdc.stdlib;

class Simplexp
{
    ParseTree node;
    Program program;
    string asmcode;
    bool negateFirstTerm;
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

        Term tmpTerm = new Term(this.node.children[0], this.program);
        return tmpTerm.is_const();
    }

    char detect_type()
    {
        Term tmpTerm;
        char tmptype = 'b';
        long current_pos = 0;
        foreach(ref child; this.node.children) {
            if(child.name == "XCBASIC.Term") {
                tmpTerm = new Term(child, this.program);
                char tmpTermType = tmpTerm.detect_type();
                long pos = this.program.type_precedence.indexOf(tmpTermType);
                if(pos > current_pos) {
                    tmptype = tmpTermType;
                    current_pos = pos;
                }
            }
        }
        return tmptype;
    }

    void eval()
    {
        char i = 0;
        Term t1 = new Term(this.node.children[i], this.program);
        t1.expected_type = this.expected_type;
        t1.eval();
        this.asmcode ~= to!string(t1);
        if(this.node.children.length > 1) {
            for(i = 1; i < this.node.children.length; i += 2) {
                string e_op = this.node.children[i].matches[0];
                Term t = new Term(this.node.children[i+1], this.program);
                t.expected_type = this.expected_type;
                t.eval();
                this.asmcode ~= to!string(t);
                string type = to!string(this.expected_type == 's' ? 'w' : this.expected_type);
                final switch(e_op) {
                    case "+":
                        this.asmcode ~= "\tadd"~type~"\n";
                    break;

                    case "-":
                        this.asmcode ~= "\tsub"~type~"\n";
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
