module statement.memshift_stmt;

import std.string, std.conv;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Memshift_stmt: Memmove_stmt
{
    mixin StmtConstructor;

    override protected string getName()
    {
        return "MEMSHIFT";
    }

    override protected string getMenmonic()
    {
        return "memshift";
    }
}
