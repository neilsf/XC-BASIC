module factor;

import pegged.grammar;
import program;
import expression;
import fun;
import std.array;
import std.conv;
import std.stdio;
import std.string;
import core.stdc.stdlib;
import excess;
import term;
import number;
import stringliteral;
import xcbarray;
import var;

class Factor
{
    ParseTree node;
    Program program;
    string asmcode;
    char expected_type;
    char type;

    this(ParseTree node, Program program)
    {
        this.node = node;
        this.program = program;
    }

    bool is_const()
    {
        string ftype = this.node.children[0].name;
        switch(ftype) {
            case "XCBASIC.Number":
                return true;

            case "XCBASIC.Var":
                ParseTree v = this.node.children[0];
                string varname = join(v.children[0].matches);
                string sigil = v.children[1].matches[0];
                if(!this.program.is_variable(varname, sigil)) {
                    this.program.error("Undefined variable: " ~ varname);
                }
                Variable var = this.program.findVariable(varname, sigil);
                return var.isConst;

            case "XCBASIC.Parenthesis":
            case "XCBASIC.Expression":
                ParseTree ex = this.node.children[0];
                auto expr = new Expression(ex, this.program);
                return expr.is_const();

            default:
                return false;
        }
    }

    real get_constval()
    {
        string ftype = this.node.children[0].name;
        switch(ftype) {
            case "XCBASIC.Number":
                ParseTree v = this.node.children[0];
                Number num = new Number(v, this.program);
                return num.type == 'f' ? num.floatval : cast(real)num.intval;

            case "XCBASIC.Var":
                ParseTree v = this.node.children[0];
                string varname = join(v.children[0].matches);
                string sigil = v.children[1].matches[0];
                if(!this.program.is_variable(varname, sigil)) {
                    this.program.error("Undefined variable: " ~ varname);
                }
                Variable var = this.program.findVariable(varname, sigil);
                return var.type == 'f' ? var.constValFloat : cast(real)var.constValInt;

            case "XCBASIC.Parenthesis":
            case "XCBASIC.Expression":
                ParseTree ex = this.node.children[0];
                auto expr = new Expression(ex, this.program);
                return expr.get_constval();

            default:
                return 0.0;
        }
    }

    char detect_type()
    {
        string ftype = this.node.children[0].name;
        char ret;
        final switch(ftype) {
            case "XCBASIC.Var":
                ParseTree v = this.node.children[0];
                string varname = join(v.children[0].matches);
                char vartype = this.program.resolve_sigil(v.children[1].matches[0]);
                ret = vartype;
            break;

            case "XCBASIC.Number":
                ParseTree v = this.node.children[0];
                Number num = new Number(v, this.program);
                ret = num.type;
            break;

            case "XCBASIC.String":
                ret = 's';
            break;

            case "XCBASIC.Fn_call":
                ParseTree fn = this.node.children[0];
                auto fun = FunFactory(fn, this.program);
                ret = fun.type;
            break;

            case "XCBASIC.Parenthesis":
                ParseTree ex = this.node.children[0].children[0];
                auto Ex = new Expression(ex, this.program);
                ret = Ex.detect_type();
            break;

            case "XCBASIC.Expression":
                ParseTree ex = this.node.children[0];
                auto Ex = new Expression(ex, this.program);
                ret = Ex.detect_type();
            break;

            case "XCBASIC.Address":
                ret = 'w';
            break;
        }

        this.type = ret;
        return ret;
    }

    void eval()
    {
    	string ftype = this.node.children[0].name;
        final switch(ftype) {
            case "XCBASIC.Var":
                ParseTree v = this.node.children[0];
                Var var = new Var(v, this.program);
                this.asmcode = var.get_asm_code();
            break;

            case "XCBASIC.Address":
                ParseTree v = this.node.children[0];
                string varname = join(v.children[0].matches);
                string sigil = "";
                if(v.children.length > 1) {
                    sigil = join(v.children[1].matches);
                }

                string lbl = "";

                if(this.program.labelExists(varname)) {
                    // a label
                    lbl = this.program.getLabelForCurrentScope(varname);
                    this.asmcode ~= "\tpaddr " ~ lbl ~ "\n";
                }
                else if(this.program.is_variable(varname, sigil)) {
                    // a variable
                    Variable var = this.program.findVariable(varname, sigil);
                    if(var.isConst) {
                        this.program.error("A constant has no address");
                    }
                    lbl = var.getLabel();
                    if(v.children.length == 2) {
                        // single variable
                        this.asmcode ~= "\tpaddr " ~ lbl ~ "\n";
                    }
                    else {
                        // array
                        auto subscript = v.children[2];
                        XCBArray arr = new XCBArray(this.program, var, subscript);
                        asmcode ~= arr.get_address();
                    }
                }
                else {
                    this.program.error("Undefined variable or label: " ~ varname);
                }



            break;

            case "XCBASIC.Number":
                ParseTree v = this.node.children[0];
                Number num = new Number(v, this.program);
                if(num.type == 'w') {
                    this.asmcode ~= "\tpword #" ~ to!string(num.intval) ~ "\n";
                }
                else if(num.type == 'b') {
                    this.asmcode ~= "\tpbyte #" ~ to!string(num.intval) ~ "\n";
                }
                else {
                    ubyte[5] bytes = float_to_hex(num.floatval);
                    this.asmcode ~= "\tpfloat $" ~ to!string(bytes[0], 16) ~ ", $" ~ to!string(bytes[1], 16) ~ ", $"
                    ~ to!string(bytes[2], 16) ~ ", $" ~ to!string(bytes[3], 16)  ~ ", $" ~ to!string(bytes[4], 16) ~ "\n";
                }
            break;

            case "XCBASIC.Expression":
            case "XCBASIC.Parenthesis":
                ParseTree ex = ftype == "XCBASIC.Expression" ? this.node.children[0] : this.node.children[0].children[0];
                auto Ex = new Expression(ex, this.program);
                Ex.eval();
                this.asmcode ~= to!string(Ex);
            break;

            case "XCBASIC.Fn_call":
                ParseTree fn = this.node.children[0];
                auto fun = FunFactory(fn, this.program);
                fun.process();
                this.asmcode ~= to!string(fun);
            break;

            case "XCBASIC.String":
                string str = join(this.node.children[0].matches[1..$-1]);
                Stringliteral sl = new Stringliteral(str, this.program);
                sl.register();
                this.asmcode ~= "\tpaddr _S" ~ to!string(Stringliteral.id) ~ "\n";
            break;

        }

        if(this.type == char.init) {
            this.detect_type();
        }

        if(this.expected_type != this.type) {
            if(indexOf("sw", this.expected_type) > -1 && indexOf("sw", this.type) > -1) {
                // Nothing to do!
            }
            else {
                char to_type = (this.expected_type == 's' ? 'w' : this.expected_type);
                this.asmcode ~= "\t" ~ to!string(this.type) ~ "to" ~ to!string(to_type) ~"\n";
                // Don't warn about b->w conversion
                if(!(this.type == 'b' && this.expected_type == 'w')) {
                    this.program.warning("Implicit type conversion");
                }
            }

        }
    }

    override string toString()
    {
        return this.asmcode;
    }
}
