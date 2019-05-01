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

class Factor
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
                ParseTree v = this.node.children[0].children[0];
                final switch(v.name) {
                    case "XCBASIC.Integer":
                    case "XCBASIC.Hexa":
                    case "XCBASIC.Binary":
                        ret = 'w';
                        break;

                    case "XCBASIC.Floating":
                        ret = 'f';
                        break;
                }
            break;

            case "XCBASIC.Fn_call":
                ParseTree fn = this.node.children[0];
                auto fun = FunFactory(fn, this.program);
                ret = fun.type;
            break;

            case "XCBASIC.Expression":
                ParseTree ex = this.node.children[0];
                auto Ex = new Expression(ex, this.program);
                ret = Ex.detect_type();
            break;
        }

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
                            this.asmcode ~= to!string(Ex2);

                            if(i == 1) {
                                // must multiply with first dimension length
                                this.asmcode ~= "\tpword #" ~ to!string(var.dimensions[1]) ~ "\n"
                                                            ~ "\tmulw\n"
                                                            ~ "\taddw\n";
                            }

                            i++;
                        }
                        // must multiply with the variable length!
                        this.asmcode ~= "\tpword #" ~ to!string(this.program.varlen[vartype]) ~ "\n"
                                                    ~ "\tmulw\n" ;
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
                string sigil = join(v.children[1].matches);

                if(!this.program.is_variable(varname, sigil)) {
                    this.program.error("Undefined variable: " ~ varname);
                }

                Variable var = this.program.findVariable(varname, sigil);
                if(var.isConst) {
                    this.program.error("A constant has no address");
                }

                this.asmcode ~= "\tpaddr " ~ var.getLabel() ~ "\n";
            break;

            case "XCBASIC.Number":
                ParseTree v = this.node.children[0];
                Number num = new Number(v, this.program);
                if(num.type == 'w') {
                    this.asmcode ~= "\tpword #" ~ to!string(num.intval) ~ "\n";
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

        }

        if(this.expected_type == 'f' && this.detect_type() == 'w') {
            this.asmcode ~= "\twtof\n";
            this.program.warning("Implicit type conversion");
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
