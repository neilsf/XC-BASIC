module fun.rnd_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Rnd_fun:Fun
{
    mixin FunConstructor;
    protected ubyte arg_count = 0;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'f', 'b'];
    }

    void process()
    {
       this.fncode ~= "\trnd" ~ to!string(this.type) ~ "\n";
    }
}
