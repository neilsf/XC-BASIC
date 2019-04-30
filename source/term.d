module term;

import pegged.grammar;
import program;
import factor;
import std.conv;
import std.stdio;
import core.stdc.stdlib;

class Term
{
    ParseTree node;
    Program program;
    string asmcode;
    char expected_type = 'w';

    this(ParseTree node, Program program)
    { 
        this.node = node;
        this.program = program;
    }

    char detect_type()
    {
        Factor tmpFact;
        char tmptype = 'w';
        foreach(ref child; this.node.children) {
            if(child.name == "XCBASIC.Factor") {
                tmpFact = new Factor(child, this.program);
                if(tmpFact.detect_type() == 'f') {
                    // if only one factor is a float,
                    // the whole term will be of type float
                    tmptype = 'f';
                    break;
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
                string type = to!string(this.expected_type);
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
   
    void _type_error()
    {
        
    }

    override string toString()
    {
        return this.asmcode;
    }
}
