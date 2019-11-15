module fun.peek_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Peek_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['w', 'b'];
    }

    void process()
    {
        if(this.arglist[0].type == 'b') {
            this.arglist[0].convert('w');
        }
        this.fncode ~= "\tpeek"~to!string(this.type)~"\n";
    }
}
