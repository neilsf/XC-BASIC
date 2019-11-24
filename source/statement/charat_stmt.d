module statement.charat_stmt;

import std.conv;

import pegged.grammar;

import language.statement;
import language.expression;

import program;

class Charat_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        auto e1 = this.node.children[0].children[0];
        auto e2 = this.node.children[0].children[1];
        auto e3 = this.node.children[0].children[2];

        auto Ex1 = new Expression(e1, this.program);
        Ex1.eval();
        if(Ex1.type == 'b') {
            Ex1.btow();
        }
        else if(Ex1.type == 'f') {
            this.program.error("Row and column must not be floats");
        }

        auto Ex2 = new Expression(e2, this.program);
        Ex2.eval();
        if(Ex2.type == 'b') {
            Ex2.btow();
        }
        else if(Ex2.type == 'f') {
            this.program.error("Row and column must not be floats");
        }
        auto Ex3 = new Expression(e3, this.program);
        Ex3.eval();
        if(Ex3.type == 'f') {
            this.program.error("Screencode must not be a float");
        }

        this.program.appendProgramSegment(to!string(Ex3)); // screencode first
        this.program.appendProgramSegment(to!string(Ex2)); // rownum second
        // multiply by column count
        this.program.appendProgramSegment("\tpword "~to!string(this.program.getColumnCount())~"\n" ~ "\tmulw\n");
        // add column
        this.program.appendProgramSegment(to!string(Ex1)); // colnum last
        this.program.appendProgramSegment("\taddw\n");
        // add screen address
        this.program.appendProgramSegment("\tpword #STDLIB_SCREEN_ADDR\n" ~ "\taddw\n");
        this.program.appendProgramSegment("\tpoke"~to!string(Ex3.type)~"\n");
    }
}
