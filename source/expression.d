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

    bool is_const()
    {
        return false;
    }

    /**
     * Pre-parses the expression to find out
     * the final result type (byte, int or float)
     */

    char detect_type()
    {
        this.type = 'b';
        Simplexp tmpSimplexp;
        foreach(ref child; this.node.children) {
            if(child.name == "XCBASIC.Simplexp") {
                tmpSimplexp = new Simplexp(child, this.program);
                char tmpSimplexpType = tmpSimplexp.detect_type();
                if(tmpSimplexpType == 'f') {
                    // if only one term is a float,
                    // the whole expr will be of type float
                    this.type = 'f';
                    break;
                }
                else if(tmpSimplexpType == 's') {
                    // if only one term is an sp,
                    // the whole expr will be of type sp
                    this.type = 's';
                    break;
                }
                else if(tmpSimplexpType == 'w' && this.type == 'b') {
                   this.type = 'w';
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
        if(this.type == char.init) {
            this.detect_type();
        }
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
                s.expected_type = this.type;
                s.eval();
                this.asmcode ~= to!string(s);
                string type = to!string(this.type == 's' ? 'w' : this.type);
                final switch(bw_op) {
                    case "&":
                        this.asmcode ~= "\tand"~type~"\n";
                    break;

                    case "|":
                        this.asmcode ~= "\tor"~type~"\n";
                    break;

                    case "^":
                        this.asmcode ~= "\txor"~type~"\n";
                    break;
                }
            }
        }
    }

    /**
     * Converts the result of the expression
     * from byte to word
     */

    void btow()
    {
        this.convert('w');
    }

    void convert(char to_type)
    {
        int[char] type_prec;
        type_prec['b'] = 0;
        type_prec['w'] = 1;
        type_prec['s'] = 2;
        type_prec['f'] = 3;
        if(indexOf("sw", this.type) > -1 && indexOf("sw", to_type) > -1) {
            // Nothing to do!
        }
        else {
            to_type = (to_type == 's' ? 'w' : to_type);
            this.asmcode ~= "\t"~to!string(this.type)~"to"~to!string(to_type)~"\n";
            if(!(indexOf("sw", to_type) && this.type == 'b') && type_prec[to_type] > type_prec[this.type]) {
                this.program.warning("Implicit type conversion");
            }
            else if(type_prec[to_type] < type_prec[this.type]) {
                this.program.warning("Implicit type conversion with truncation or possible loss of precision");
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

    real eval_const()
    {
        return 1.0;
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

class LabelExpression: Expression
{
    this(ParseTree node, Program program)
    {
        super(node, program);
    }

    override void eval()
    {
        string lab = join(this.node.matches);
        if(!this.program.labelExists(lab)) {
            this.program.error("Label "~lab~" does not exist");
        }

        this.asmcode =
            "\tlda #<_L" ~ lab ~ "\n" ~
            "\tpha\n" ~
            "\tlda #>_L" ~ lab ~ "\n" ~
            "\tpha\n";
    }
}
