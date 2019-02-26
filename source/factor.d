module factor;

import pegged.grammar;
import program;
import expression;
import fun;
import std.array;
import std.conv;
import std.stdio;
import core.stdc.stdlib;

class Factor
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
    	string ftype = this.node.children[0].name;
        final switch(ftype) {
            case "XCBASIC.Var":
                ParseTree v = this.node.children[0];
                string varname = join(v.children[0].matches);
                char vartype = this.program.type_conv(v.children[1].matches[0]);
                if(!this.program.is_variable(varname)) {
                    this.program.error("Undefined variable: " ~ varname);
                }

                Variable var = this.program.findVariable(varname);

                if(var.isConst) {
                    this.asmcode ~= "\tpword #" ~ to!string(var.constValInt) ~ "\n";
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

            case "XCBASIC.Number":
                ParseTree v = this.node.children[0];
                string num_str = join(v.children[0].matches);
                int num = to!int(num_str);
                if(num < -32768 || num > 65535) {
                    this.program.error("Number out of range");
                }
                this.asmcode ~= "\tpword #" ~ num_str ~ "\n";
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
