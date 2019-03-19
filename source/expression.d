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

    this(ParseTree node, Program program)
    { 
        this.node = node;
        this.program = program;
    }

    void eval()
    {
        char i = 0;
        Simplexp s1 = new Simplexp(this.node.children[i], this.program);
        s1.eval();
        this.asmcode ~= to!string(s1);

        if(this.node.children.length > 1) {
            for(i = 1; i < this.node.children.length; i += 2) {
                string bw_op = this.node.children[i].matches[0];
                Simplexp s = new Simplexp(this.node.children[i+1], this.program);
                s.eval();
                this.asmcode ~= to!string(s);
                final switch(bw_op) {
                    case "and":
                        this.asmcode ~= "\tandw\n";
                    break;

                    case "or":
                        this.asmcode ~= "\torw\n";
                    break;

                    case "xor":
                        this.asmcode ~= "\txorw\n";
                    break;
                }
            }
        }
    }
   
    void _type_error()
    {

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

