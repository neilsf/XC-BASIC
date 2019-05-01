module expression;

import pegged.grammar;
import program;
import term;
import std.conv;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import stringliteral;
import simplexp;

class Expression
{
    ParseTree node;
    Program program;
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
        this.type = 'w';
        Simplexp tmpSimplexp;
        foreach(ref child; this.node.children) {
            if(child.name == "XCBASIC.Simplexp") {
                tmpSimplexp = new Simplexp(child, this.program);
                if(tmpSimplexp.detect_type() == 'f') {
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
        char i = 0;
        this.detect_type();
        Simplexp s1 = new Simplexp(this.node.children[i], this.program);
        s1.expected_type = this.type;
        s1.eval();
        this.asmcode ~= to!string(s1);

        if(this.node.children.length > 1) {
            if(this.type == 'f') {
                this._type_error();
            }
            for(i = 1; i < this.node.children.length; i += 2) {
                string bw_op = this.node.children[i].matches[0];
                Simplexp s = new Simplexp(this.node.children[i+1], this.program);
                s.eval();
                this.asmcode ~= to!string(s);
                final switch(bw_op) {
                    case "&":
                        this.asmcode ~= "\tandw\n";
                    break;

                    case "|":
                        this.asmcode ~= "\torw\n";
                    break;

                    case "^":
                        this.asmcode ~= "\txorw\n";
                    break;
                }
            }
        }
    }
   
    void _type_error()
    {
        this.program.error("Bitwise operations cannot be performed on floats");
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

