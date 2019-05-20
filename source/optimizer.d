module optimizer;

import std.string, std.array, std.uni;

class Optimizer
{
    string incode;
    string outcode;

    const string[] pushers = [
        "pzero",  "pone", "pbyte", "pword",
        "pwvar", "pbarray", "pwarray", "cmpblt",
        "cmpblte", "cmpbgte", "cmpbeq", "cmpbneq",
        "cmpbgt", "cmpweq", "cmpwneq", "cmpwlt",
        "cmpwgte", "cmpwgt", "cmpwlte", "addb",
        "orb", "andb", "xorb", "mulb", "mulw",
        "divb", "peekb", "peekw", "deek", "inkeyb",
        "inkeyw", "rndb", "rndw"
    ];

    const string[] pullers = [
        "pbarray", "pwarray", "plb2var", "plw2var",
        "plbarray", "pwbarray", "cmpblt", "cmpblte",
        "cmpbgte", "cmpbeq", "cmpbneq", "cmpbgt",
        "cmpweq", "cmpwneq", "addb", "orb", "andb",
        "xorb", "mulb", "mulw", "divb", "pokeb",
        "pokew", "doke", "peekb", "peekw", "deek",
        "sys", "usr", "stdlib_printw", "textat", "wat",
        "bat"
    ];

    this(string incode)
    {
        this.incode = incode;
    }

    void run()
    {
        this.outcode = "";
        string[] lines = splitLines(this.incode);
        bool opt_enabled = false;
        bool pushf = false;
        bool pullf = false;
        for(int i=0; i<lines.length; i++) {
            string line = lines[i];
            if(line == "\t; !!opt_start!!") {
                opt_enabled = true;
                continue;
            }
            else if(line == "\t; !!opt_end!!") {
                opt_enabled = false;
                continue;
            }

            if(!opt_enabled) {
                this.outcode ~= line ~ "\n";
                continue;
            }

            string opc = this.get_opc(line);
            if(opc == "") {
                continue;
            }



        }
    }

    string get_opc(string line)
    {
        if(line == "") {
            return "";
        }
        string[] parts = line.split!isWhite;
        if(this.is_puller(parts[0]) || this.is_pusher(parts[0])) {
            return parts[0];
        }
        else if(this.is_puller(parts[1]) || this.is_pusher(parts[1])) {
            return parts[0];
        }
        else {
            return "";
        }
    }

    bool is_puller(string opc)
    {
        foreach(ref elem; this.pullers) {
            if(elem == opc) {
                return true;
            }
        }

        return false;
    }

    bool is_pusher(string opc)
    {
        foreach(ref elem; this.pushers) {
            if(elem == opc) {
                return true;
            }
        }

        return false;
    }
}
