module expression;

import pegged.grammar;
import program;
import term;
import std.conv;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import stringliteral;

class Expression
{
    ParseTree node;
    Program program;
    bool negateFirstTerm;
    string asmcode;
    char type;

    this(ParseTree node, Program program)
    { 
        this.node = node;
        this.program = program;
    }

    /**
     * Pre-parses the expression to find out
     * the final result type (int or float)
     */

    char detect_type()
    {
        this.type = 'i';
        Term tmpTerm;
        foreach(ref child; this.node.children) {
            if(child.name == "TINYBASIC.Term") {
                tmpTerm = new Term(child, this.program);
                if(tmpTerm.detect_type() == 'f') {
                    // if only one term is a float,
                    // the whole expr will be of type float
                    this.type = 'f';
                    break;
                }
            }
        }

        return this.type;
    }

    /**
     * Evaluates the expression
     */

    void eval()
    {
    	this.negateFirstTerm = (this.node.matches[0] == "-");
        char i = 0; 
    	Term t1 = new Term(this.node.children[i], this.program);
        t1.eval();
        this.asmcode ~= to!string(t1);
        if(this.negateFirstTerm) {
            this.asmcode ~= "\tnegw\n";
        }
        if(this.node.children.length > 1) {
            for(i = 1; i < this.node.children.length; i += 2) {
                string e_op = this.node.children[i].matches[0];
                Term t = new Term(this.node.children[i+1], this.program);
                t.eval();
                this.asmcode ~= to!string(t);
                final switch(e_op) {
                    case "+":
                        this.asmcode ~= "\taddw\n";
                    break;

                    case "-":
                        this.asmcode ~= "\tsubw\n";
                    break;
                }
            }
        }
    }
   
    void _type_error()
    {
        this.program.error("Only byte types can make part of a logical expression");
    }

    bool is_numeric_constant()
    {
        string expr = join(this.node.matches);
        bool success;
        try {
            auto x = to!int(expr);
            success = true;
        }
        catch(Exception e) {
            success = false;
        }

        return success;
    }

    short as_int()
    {
        string expr = join(this.node.matches);
        return to!short(expr);
    }

    override string toString()
    {
        return this.asmcode;
    }
}

class StringExpression: Expression
{
    this(ParseTree node, Program program)
    {
        super(node, program);
    }

    override void eval()
    {
        // only single string literals for now
        auto sl = new Stringliteral(join(this.node.matches), this.program);
        sl.register();
        this.asmcode =
            "\tlda #<_S" ~ to!string(Stringliteral.id) ~ "\n" ~
            "\tpha\n" ~
            "\tlda #>_S" ~ to!string(Stringliteral.id) ~ "\n" ~
            "\tpha\n";
    }
}

