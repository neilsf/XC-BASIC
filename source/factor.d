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
                string varname = join(v.children[0].matches);
                string sigil = v.children[1].matches[0];

                if(!this.program.is_variable(varname, sigil)) {
                    this.program.error("Undefined variable: " ~ varname);
                }

                Variable var = this.program.findVariable(varname, sigil);
                char vartype = var.type;

                if(var.isConst) {
                    if(var.type == 'w') {
                        this.asmcode ~= "\tpword #" ~ to!string(var.constValInt) ~ "\n";
                    }
                    else if(var.type == 'b') {
                        this.asmcode ~= "\tpbyte #" ~ to!string(var.constValInt) ~ "\n";
                    }
                    else {
                        ubyte[5] bytes = float_to_hex(to!real(var.constValFloat));
                            this.asmcode ~= "\tpfloat $" ~ to!string(bytes[0], 16) ~ ", $" ~ to!string(bytes[1], 16) ~ ", $"
                            ~ to!string(bytes[2], 16) ~ ", $" ~ to!string(bytes[3], 16)  ~ ", $" ~ to!string(bytes[4], 16) ~ "\n";
                    }

                }
                else {
                    if(v.children.length > 2) {
                        /* any variable can be accessed as an array
                        if(var.dimensions[0] == 1 && var.dimensions[1] == 1) {
                            this.program.error("Not an array");
                        }
                        */
                        auto subscript = v.children[2];
                        if((var.dimensions[1] == 1 && subscript.children.length > 1) || (var.dimensions[1] > 1 && subscript.children.length == 1)) {
                            this.program.error("Bad subscript");
                        }
                        ushort[2] dimensions;
                        ubyte i = 0;
                        foreach(ref expr; subscript.children) {
                            Expression Ex2 = new Expression(expr, this.program);
                            Ex2.eval();
                            if(Ex2.type == 'b') {
                                Ex2.btow();
                            }
                            else if(Ex2.type == 'f') {
                                this.program.error("Bad subscript");
                            }
                            this.asmcode ~= to!string(Ex2);

                            if(i == 1) {
                                // must multiply with first dimension length
                                this.asmcode ~= "\tpword #" ~ to!string(var.dimensions[1]) ~ "\n"
                                                            ~ "\tmulw\n"
                                                            ~ "\taddw\n";
                            }

                            i++;
                        }
                        // if not a byte, must multiply with the variable length!
                        if(var.type != 'b') {
                            this.asmcode ~= "\tpword #" ~ to!string(this.program.varlen[vartype]) ~ "\n"
                                          ~ "\tmulw\n" ;
                        }

                        this.asmcode ~= "\tp" ~ to!string(vartype) ~"array "~ var.getLabel() ~ "\n";
                    }
                    else {
                        this.asmcode ~= "\tp" ~ to!string(vartype) ~ "var " ~ var.getLabel() ~ "\n";
                    }
                }

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
                    lbl =this.program.getLabelForCurrentScope(varname);
                }
                else if(this.program.is_variable(varname, sigil)) {
                    Variable var = this.program.findVariable(varname, sigil);
                    if(var.isConst) {
                        this.program.error("A constant has no address");
                    }
                    lbl = var.getLabel();
                }
                else {
                    this.program.error("Undefined variable or label: " ~ varname);
                }

                this.asmcode ~= "\tpaddr " ~ lbl ~ "\n";

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
                ParseTree ex = this.node.children[0];
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

	        case "XCBASIC.Parenthesis":
	            ParseTree ex = this.node.children[0].children[0];
                auto Ex = new Expression(ex, this.program);
                Ex.eval();
                this.asmcode ~= to!string(Ex);
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

    void _type_error()
    {

    }

    override string toString()
    {
        return this.asmcode;
    }
}
