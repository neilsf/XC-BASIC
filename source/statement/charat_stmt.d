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
        if(Ex1.type != 'b') {
            Ex1.convert('b');
        }
        auto Ex2 = new Expression(e2, this.program);
        Ex2.eval();
        if(Ex2.type != 'b') {
            Ex2.convert('b');
        }
        auto Ex3 = new Expression(e3, this.program);
        Ex3.eval();
        if(Ex3.type != 'b') {
            Ex3.convert('b');
        }

        this.program.appendProgramSegment(to!string(Ex3)); // screencode first
        this.program.appendProgramSegment(to!string(Ex2)); // rownum second
        // multiply by 40
        this.program.appendProgramSegment("\tpword #40\n" ~ "\tmulw\n");
        // add column
        this.program.appendProgramSegment(to!string(Ex1)); // colnum last
        this.program.appendProgramSegment("\taddw\n");
        // add 1024
        this.program.appendProgramSegment("\tpword #1024\n" ~ "\taddw\n");
        this.program.appendProgramSegment("\tpoke"~to!string(Ex3.type)~"\n");
    }
}
