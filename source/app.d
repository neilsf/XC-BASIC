import std.stdio, std.file, std.array, std.string, std.getopt, std.path;
import core.stdc.stdlib;
import tbgrammar;
import program;
import std.conv;

void main(string[] args)
{
    string filename = args[1];
    string outfile;

    File infile;

    try {
        infile = File(filename, "r");
    }
    catch(Exception e) {
        stderr.writeln("Failed to open source file (" ~ filename ~ ")");
        exit(1);
    }

    string source = "";
    while(!infile.eof){
        source = source ~ infile.readln();
    }

    auto ast = XCBASIC(source);
    if(!ast.successful) {
        auto lines = splitLines(to!string(ast));
        string line = lines[$-1];
        stderr.writeln("Parser error: " ~ strip(line, " +-"));
        exit(1);
    }

    //writeln(ast); exit(1);

    auto program = new Program();
    program.processAst(ast);
    writeln(program.getAsmCode());
}
