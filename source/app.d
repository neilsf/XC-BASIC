import std.stdio, std.file, std.array, std.string, std.getopt, std.path, std.regex;
import core.stdc.stdlib;
import tbgrammar;
import program;
import std.conv;
import globals;
import optimizer;

int line_count = 0;

/**
 * Application entry point
 */

void main(string[] args)
{
    if(args.length < 2) {
        stderr.writeln("Error: input file not specified");
        exit(1);
    }

    string filename = args[1];

    string source = build_source(filename);
    auto ast = XCBASIC(source);

    if(!ast.successful) {
        auto lines = splitLines(to!string(ast));
        string line = lines[$-1];
        stderr.writeln("Parser error: " ~ strip(line, " +-"));
        //stderr.writeln(ast);
        exit(1);
    }

    //stderr.writeln(ast); exit(1);

    auto program = new Program();
    program.source_path = absolutePath(dirName(filename));
    program.processAst(ast);
    string code = program.getAsmCode();
    auto optimizer = new Optimizer(code);
    optimizer.run();
    writeln(optimizer.outcode);
}

/**
 * Recursively builds a source string from file
 * along with its includes
 */

string build_source(string filename)
{
    File infile;

    try {
        infile = File(filename, "r");
    }
    catch(Exception e) {
        stderr.writeln("Failed to open source file (" ~ filename ~ ")");
        exit(1);
    }

    string source = "";

    int local_line_count = 0;
    while(!infile.eof){

        line_count++;
        local_line_count++;

        globals.source_file_map~=baseName(filename);
        globals.source_line_map~=local_line_count;

        string line = strip(infile.readln(), "\n");
        source = source ~ line ~ "\n";

        auto m = matchFirst(line, regex(`\s*(include|INCLUDE)\s*"([^"]+)"\s*`));
        if(m) {
            string fname = m[2];
            string path = absolutePath(dirName(filename)) ~ "/" ~ fname;
            source ~= build_source(path);
        }
    }

    return source;
}
