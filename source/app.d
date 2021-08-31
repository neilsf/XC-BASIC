import std.stdio, std.file, std.array, std.string, std.getopt, std.path, std.regex, std.random, std.process;
import core.stdc.stdlib;
import language.grammar;
import program;
import std.conv;
import globals;
import optimizer;

int line_count = 0;

/**
 * Variables that hold command-line options
 */

bool noopt = false;
string output_type = "prg";
version(Windows) {
    string dasm = "dasm.exe";
}
else {
    string dasm = "dasm";
}
string symbolfile="";
string listfile="";

/**
 * Version
 */

string compiler_version = "v2.3.12";

/**
 * Application entry point
 */

void main(string[] args)
{
    auto helpInformation = getopt(args,
        "dasm|d", &dasm,
        "symbol|s", &symbolfile,
        "list|l", &listfile,
        "noopt|n", &noopt,
        "output|o", &output_type
    );

    if(helpInformation.helpWanted) {
        display_help(0);
    }

    if(output_type != "prg" && output_type != "asm") {
        stderr.writeln("** ERROR ** Invalid value for option -o");
        exit(1);
    }

    if(args.length < 3) {
        display_help(1, "** ERROR ** Too few command line arguments.\n");
    }

    string filename = args[1];
    string outname = args[2];

    string source = build_source(filename);
    auto ast = XCBASIC(source);

    if(!ast.successful) {
        auto lines = splitLines(to!string(ast));
        string line = lines[$-1];
        stderr.writeln("** ERROR ** Parser error: " ~ strip(line, " +-"));
        exit(1);
    }

    auto program = new Program();
    program.source_path = absolutePath(dirName(filename));
    program.processAst(ast);
    string code = program.getAsmCode();
    if(!noopt) {
        auto optimizer = new Optimizer(code);
        optimizer.run();
        code = optimizer.outcode;
    }

    if(output_type == "prg") {

        // Write assembly program to temp location
        string tmpDir = tempDir();
        auto rnd = Random(42);
        auto u = uniform!uint(rnd);
        string tmpdir;

        version(Windows) {
            tmpdir = tempDir();
        }
        else {
            tmpdir = tempDir() ~ dirSeparator;
        }

        string asm_filename = tmpdir ~ "xcbtmp_" ~ to!string(u, 16) ~ ".asm";
        File outfile = File(asm_filename, "w");
        outfile.write(code);
        outfile.close();

        version(Windows) {
            dasm = `"` ~ dasm ~ `"`;
            asm_filename = `"` ~ asm_filename ~ `"`;
            outname = `"` ~ outname ~ `"`;
            if(symbolfile != "") {
                symbolfile = `"` ~ symbolfile ~ `"`;
            }
            if(listfile != "") {
                listfile = `"` ~ listfile ~ `"`;
            }
        }

        string cmd = dasm ~ " " ~ asm_filename ~ " -o" ~ outname;
        if(symbolfile != "") {
            cmd ~= " -s" ~ symbolfile;
        }
        if(listfile != "") {
            cmd ~= " -l" ~ listfile;
        }
        auto dasm_cmd = executeShell(cmd);
        if(dasm_cmd.status != 0) {
            stderr.writeln("** ERROR ** There has been an error while trying to execute DASM, please see the bellow message.");
            stderr.writeln("Tried to execute: " ~ cmd);
            stderr.writeln(dasm_cmd.output);
            exit(1);
        }
        else {
            stdout.write(dasm_cmd.output);
            exit(0);
        }
    }
    else {
        File outfile = File(outname, "w");
        outfile.write(code);
        outfile.close();
        stdout.writeln("Complete.");
        exit(0);
    }
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
        stderr.writeln("** ERROR ** Failed to open source file (" ~ filename ~ ")");
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

        auto ast = XCBASIC(line);
        auto bline = ast.children[0].children[0];
        foreach(ref node; bline.children) {
            if(node.name == "XCBASIC.Statements") {
                foreach(ref statement; node.children) {
                    if(statement.children[0].name == "XCBASIC.Include_stmt") {
                        string fname = join(statement.children[0].children[0].matches[1..$-1]);
                        string path = absolutePath(dirName(filename)) ~ "/" ~ fname;
                        source ~= build_source(path);
                    }
                }
            }
        }
    }

    return source;
}

/**
 * Display help message and exit
 */

void display_help(int exit_code, string error_msg = "")
{
    stdout.writeln(error_msg ~
`
XC=BASIC compiler version ` ~ compiler_version ~ `
Copyright (c) 2019-2020 by Csaba Fekete
Usage: xcbasic64 [options] <inputfile> <outputfile> [options]
Options:
   -o
  --output=     Output type: "prg" (default) or "asm"

   -d
  --dasm=       Path to the DASM executable.
                Defaults to "dasm.exe" (Windows) or "dasm" (Linux/Mac)

   -s
  --symbol=     Symbol dump file name. This is passed to DASM as it is.

   -l
  --list=       List file name. This is passed to DASM as it is.

   -n
  --noopt       Do NOT run the optimizer

   -h
  --help        Show this help
`
    );
    exit(exit_code);
}
