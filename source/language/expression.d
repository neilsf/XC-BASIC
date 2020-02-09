module language.expression;

import pegged.grammar;
import program;
import language.term;
import std.conv;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import language.stringliteral;
import language.simplexp;
import language.factor;

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
     * An expression is considered to be constant
     * if it has only one member and that member is
     * a numeric literal or a constant
     */

    bool is_const()
    {
        if(this.node.children.length > 1) {
            return false;
        }

        Simplexp tmpSimp = new Simplexp(this.node.children[0], this.program);
        return tmpSimp.is_const();
    }

    real get_constval()
    {
        Factor tmpFact = new Factor(this.node.children[0].children[0].children[0], this.program);
        return tmpFact.get_constval();
    }

    /**
     * Pre-parses the expression to find out
     * the final type (byte, int, long or float)
     */

    char detect_type()
    {
        this.type = 'b';
        Simplexp tmpSimplexp;
        long current_pos = 0;
        foreach(ref child; this.node.children) {
            if(child.name == "XCBASIC.Simplexp") {
                tmpSimplexp = new Simplexp(child, this.program);
                char tmpSimplexpType = tmpSimplexp.detect_type();
                long pos = this.program.type_precedence.indexOf(tmpSimplexpType);
                if(pos > current_pos) {
                    this.type = tmpSimplexpType;
                    current_pos = pos;
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
        if(indexOf("sw", this.type) > -1 && indexOf("sw", to_type) > -1) {
            // Nothing to do!
        }
        else {
            to_type = (to_type == 's' ? 'w' : to_type);
            this.asmcode ~= "\t"~to!string(this.type)~"to"~to!string(to_type)~"\n";
            if(this.program.type_precedence.indexOf(to_type) > this.program.type_precedence.indexOf(this.type)) {
                this.program.warning("Implicit type conversion");
            }
            else {
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
