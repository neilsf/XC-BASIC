module fun.sqr_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Sqr_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'l', 'f'];
    }

    void process()
    {
        if(this.type != this.arglist[0].detect_type()) {
            this.program.error("The sqr() function's argument type and return type must match");
        }

        this.fncode ~= "\tsqr" ~ to!string(this.type) ~ "\n";
    }
}

