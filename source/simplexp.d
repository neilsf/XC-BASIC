module simplexp;

import pegged.grammar;
import program;
import term;
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

    char detect_type()
    {
        char type = 'b';
        Term tmpTerm;
        foreach(ref child; this.node.children) {
            if(child.name == "XCBASIC.Term") {
                tmpTerm = new Term(child, this.program);
                char tmpTermType = tmpTerm.detect_type();
                if(tmpTermType == 'f') {
                    // if only one term is a float,
                    // the whole expr will be of type float
                    type = 'f';
                    break;
                }
                else if(tmpTermType == 's') {
                    // if only one term is an sp,
                    // the whole expr will be of type sp
                    type = 's';
                    break;
                }
                else if(tmpTermType == 'w' && type == 'b') {
                    type = 'w';
                }
            }
        }

        return type;
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
