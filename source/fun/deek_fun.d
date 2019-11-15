module fun.deek_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Deek_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w'];
    }

    void process()
    {
        this.fncode ~= "\tdeek\n";
    }
}
