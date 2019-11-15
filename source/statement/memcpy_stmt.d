module statement.memcpy_stmt;

import std.string, std.conv;
import pegged.grammar;
import language.statement, language.expression;
import program;

class Memcpy_stmt: Memmove_stmt
{
    mixin StmtConstructor;

    override protected string getName()
    {
        return "MEMCPY";
    }

    override protected string getMenmonic()
    {
        return "memcpy";
    }
}
