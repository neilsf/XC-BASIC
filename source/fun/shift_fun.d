module fun.shift_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Shift_fun:Fun
{
    mixin FunConstructor;

    protected ubyte arg_count = 1;
    protected ubyte opt_arg_count = 1;

    override protected char[] getPossibleTypes()
    {
        return ['b', 'w', 'l'];
    }

    void process()
    {
        if(this.type != this.arglist[0].detect_type()) {
            this.program.error(this.direction ~ "shift(): argument and return types must match");
        }

        bool is_const;
        ubyte cval;

        if(this.arglist[1] !is null) {

            if(this.arglist[1].detect_type() != 'b') {
                this.program.error("Argument #2 of lshift() must be a byte");
            }

            is_const = this.arglist[1].is_const;
            if(is_const) {
                cval = cast(ubyte)this.arglist[1].get_constval();
                this.arglist[1] = null;
            }
        }
        else {
            is_const = true;
            cval = 1;
        }

        this.fncode ~= "\t" ~ this.direction ~  "shift" ~ to!string(this.type) ~ (is_const ? ("c " ~ to!string(cval)) : "") ~ "\n";
    }
}
