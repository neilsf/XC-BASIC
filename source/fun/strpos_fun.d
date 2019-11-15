module fun.strpos_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Strpos_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 2;

    override protected char[] getPossibleTypes()
    {
        return ['b'];
    }

    void process()
    {
        if(this.arglist[0].detect_type() != 's' || this.arglist[1].detect_type() != 's') {
            this.program.error("Wrong type passed to strcmp()");
        }
        this.program.use_stringlib = true;
        this.fncode ~= "\tstrpos\n";
    }
}
