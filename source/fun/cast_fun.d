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
        return ['b', 'w', 'f'];
    }

    void process()
    {
        char argtype = this.arglist[0].type;
        if(argtype == this.type) {
            this.program.error("Can't cast to the same type");
        }

        if(this.type == 'b') {
            this.program.warning("Possible truncation or loss of precision");
        }

        this.fncode = "\t"~to!string(this.arglist[0].type)~"to"~to!string(this.type)~"\n";
    }
}
