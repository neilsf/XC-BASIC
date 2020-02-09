module fun.cast_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Cast_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['b', 'w', 'f', 'l'];
    }

    void process()
    {
        char argtype = this.arglist[0].type;
        if(argtype == this.type) {
            this.program.error("Can't cast to the same type");
        }

        this.fncode = "\t"~to!string(this.arglist[0].type)~"to"~to!string(this.type)~"\n";
    }
}
