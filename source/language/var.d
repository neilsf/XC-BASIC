module language.var;

import program;
import pegged.grammar;
import std.conv, std.stdio;
import language.xcbarray;
import std.array;
import language.excess;

/**
 *  This class represents a variable expression in the AST
 */

class Var
{
    ParseTree node;
    Program program;
    string asm_code;
    Variable program_var;

    this(ParseTree node, Program program)
    {
        this.program = program;
        this.node = node;
        string varname = join(this.node.children[0].matches);
        string sigil = this.node.children[1].matches[0];

        if(!this.program.is_variable(varname, sigil)) {
            this.program.error("Undefined variable: " ~ varname);
        }

        this.program_var = this.program.findVariable(varname, sigil);
    }

    string get_asm_code()
    {
        string asmcode;
        char vartype = program_var.type;

        if(program_var.isConst) {
            if(program_var.type == 'w') {
                asmcode ~= "\tpword #" ~ to!string(program_var.constValInt) ~ "\n";
            }
            else if(program_var.type == 'b') {
                asmcode ~= "\tpbyte #" ~ to!string(program_var.constValInt) ~ "\n";
            }
            else {
                ubyte[5] bytes = float_to_hex(to!real(program_var.constValFloat));
                    asmcode ~= "\tpfloat $" ~ to!string(bytes[0], 16) ~ ", $" ~ to!string(bytes[1], 16) ~ ", $"
                    ~ to!string(bytes[2], 16) ~ ", $" ~ to!string(bytes[3], 16)  ~ ", $" ~ to!string(bytes[4], 16) ~ "\n";
            }

        }
        else {
            if(this.node.children.length > 2) {
                /* any variable can be accessed as an array
                if(var.dimensions[0] == 1 && var.dimensions[1] == 1) {
                    this.program.error("Not an array");
                }
                */
                auto subscript = this.node.children[2];
                XCBArray arr = new XCBArray(this.program, program_var, subscript);
                asmcode ~= arr.lookup();
            }
            else {
                asmcode ~= "\tp" ~ to!string(vartype) ~ "var " ~ program_var.getLabel() ~ "\n";
            }
        }

        return asmcode;
    }

    byte get_bconstval()
    {
        return cast(byte)program_var.constValInt;

    }

    short get_wconstval()
    {
        return cast(short)program_var.constValInt;
    }

    real get_fconstval()
    {
        return program_var.constValFloat;
    }
}
