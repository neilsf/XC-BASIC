module fun.abs_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Abs_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'f'];
    }

    void process()
    {
        if(this.type != this.arglist[0].detect_type()) {
            this.program.error("The abs() function's argument type and return type must match");
        }

        this.fncode ~= "\tabs" ~ to!string(this.type) ~ "\n";
    }
}
