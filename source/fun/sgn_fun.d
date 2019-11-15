module fun.sgn_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Sgn_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w'];
    }

    void process()
    {
        char argtype = this.arglist[0].detect_type();

        if(indexOf("bwf", argtype) == -1) {
            this.program.error("The argument passed to SGN must be an int or float");
        }

        if(argtype == 'b') {
            this.arglist[0].convert('w');
        }

        this.fncode ~= "\tsgn" ~ to!string(this.type) ~ "\n";
    }
}
