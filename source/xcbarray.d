module xcbarray;

import pegged.grammar;
import program;
import expression;
import std.conv;

class XCBArray
{
    Program program;
    Variable var;
    ParseTree subscript;

    this(Program program, Variable var, ParseTree subscript)
    {
        this.program = program;
        this.var = var;
        this.subscript = subscript;
        this.validate_subscript();
    }

    /**
     * Generates assembly code for array lookup operation
     */

    string lookup()
    {
        return this.is_fast() ? this.fast_lookup() : this.slow_lookup();
    }

    private string fast_lookup()
    {
        string asmcode = "";
        Expression ex = new Expression(this.subscript.children[0], this.program);
        ex.eval();
        asmcode ~= to!string(ex);
        asmcode ~= "\tpbarray_fast " ~ var.getLabel() ~ "\n";
        return asmcode;
    }

    private string slow_lookup()
    {
        string asmcode = this.vector_code();
        asmcode ~= "\tp" ~ to!string(var.type) ~"array "~ var.getLabel() ~ "\n";
        return asmcode;
    }

    /**
     * Generates assembly code for array store operation
     */

    string store()
    {
        return this.is_fast() ? this.fast_store() : this.slow_store();
    }

    private string fast_store()
    {
        string asmcode = "";
        Expression ex = new Expression(this.subscript.children[0], this.program);
        ex.eval();
        asmcode ~= to!string(ex);
        asmcode ~= "\tplbarray_fast " ~ var.getLabel() ~ "\n";
        return asmcode;
    }

    private string slow_store()
    {
        string asmcode = this.vector_code();
        asmcode ~= "\tpl" ~ to!string(var.type) ~"array "~ var.getLabel() ~ "\n";
        return asmcode;
    }

    /**
     * Generates assembly code for getting the address of an array member
     */

    string get_address()
    {
        string asmcode = this.vector_code();
        asmcode ~= "\tpaddr " ~ var.getLabel() ~ "\n";
        asmcode ~= "\taddw\n";
        return asmcode;
    }

    /**
     * Generates assembly code for increasing or decreasing an array member
     */

    string incordec(string op = "inc")
    {
        string asmcode;
        if(this.is_fast()) {
            Expression ex = new Expression(this.subscript.children[0], this.program);
            ex.eval();
            asmcode ~= to!string(ex);
            asmcode ~= "\t" ~ op ~ "barrb " ~ var.getLabel() ~ "\n";
            return asmcode;
        }

        asmcode ~= this.vector_code();
        asmcode ~= "\t" ~ op ~ to!string(var.type) ~ "arr " ~ var.getLabel() ~ "\n";
        return asmcode;
    }

    private void validate_subscript()
    {
        if((var.dimensions[1] == 1 && this.subscript.children.length > 1)
         || (var.dimensions[1] > 1 && this.subscript.children.length == 1)) {
            this.program.error("Bad subscript");
        }
    }

    private string vector_code()
    {
        ubyte i = 0;
        string asmcode = "";
        foreach(ref expr; this.subscript.children) {
            Expression ex = new Expression(expr, this.program);
            ex.eval();
            if(ex.type == 'b') {
                ex.btow();
            }
            else if(ex.type == 'f') {
                this.program.error("Bad subscript");
            }

            asmcode ~= to!string(ex);

            if(i == 1) {
                // must multiply with first dimension length
                asmcode ~= "\tpword #" ~ to!string(var.dimensions[1]) ~ "\n"
                         ~ "\tmulw\n"
                         ~ "\taddw\n";
            }
            i++;
        }
        // if not a byte, must multiply with the variable length!
        if(var.type == 'w' || var.type == 's') {
            // if it's an integer, just shift one bit to the left
            asmcode ~= "\tdblw\n";
        }
        else if(var.type == 'f') {
            // else multiply by 5
            asmcode ~= "\tpword #" ~ to!string(this.program.varlen[var.type]) ~ "\n"
                     ~ "\tmulw\n" ;
        }

        return asmcode;
    }

    /**
     * Tells whether the operation can use fast version
     */

    private bool is_fast()
    {
        if(this.var.type == 'b' && this.subscript.children.length == 1) {
            Expression ex = new Expression(this.subscript.children[0], this.program);
            if(ex.detect_type() == 'b') {
                return true;
            }
        }

        return false;
    }
}
