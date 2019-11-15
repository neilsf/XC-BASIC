module fun.atn_fun;

import language.fun, language.expression;
import std.string, std.conv;
import pegged.grammar;
import program;

class Atn_fun:TrigonometricFun
{
    mixin FunConstructor;

    override string getName()
    {
        return "atn";
    }
}
