module fun.val_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Val_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['b', 'w', 'f'];
    }

    void process()
    {
        this.program.use_stringlib = true;
        char argtype = this.arglist[0].type;
        if(argtype != 's') {
            this.program.error("Argument 1 of VAL() must be a string pointer");
        }

        this.fncode = "\tval"~to!string(this.type)~"\n";
    }
}
