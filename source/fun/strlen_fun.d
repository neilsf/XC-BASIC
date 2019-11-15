module fun.strlen_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Strlen_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['b'];
    }

    void process()
    {
        if(this.arglist[0].detect_type() != 's') {
            this.program.error("Wrong type passed to strlen()");
        }

        this.program.use_stringlib = true;
        this.fncode ~= "\tstrlen\n";
    }
}
