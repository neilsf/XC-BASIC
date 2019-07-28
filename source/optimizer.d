module optimizer;

import std.string, std.array, std.uni;
import opt;

class Optimizer
{
    string outcode;

    this(string incode)
    {
        string code;
        Replace_sequences op1 = new Replace_sequences(incode);
        op1.run();
        Remove_stack_ops op2 = new Remove_stack_ops(op1.outcode);
        op2.run();
        this.outcode = op2.outcode;
    }
}

template Optimization_pass_ctor()
{
    this(string incode)
    {
        this.incode = incode;
    }
}

abstract class Optimization_pass
{
    public string incode;
    public string outcode;

    abstract void run();
}

/**
 * Replaces sequences of pseudo-ops with
 * equivalent but faster ones
 */

class Replace_sequences: Optimization_pass
{
    mixin Optimization_pass_ctor;

    const string[] sequences = [
        "pbyte_pbyte_addb",
        "pbyte_pbyte_subb",
        "pword_pword_addw",
        "pword_pword_subw"
    ];

    private bool match_sequences(string candidate)
    {
        ulong len = candidate.length;
        foreach(item; this.sequences) {
            if(len <= item.length && item[0..len-1] == candidate) {
                return true;
            }
        }
        return false;
    }

    private bool full_match(string candidate)
    {
        foreach(item; this.sequences) {
            if(item == candidate) {
                return true;
            }
        }
        return false;
    }

    override void run()
    {
        bool opt_enabled = false;
        string[] lines = splitLines(this.incode);
        string accumulated_sequence = "";
        string[] accumulated_code;
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

            auto expr = regex(r"\t([a-z]+)(\s.+)?");
            auto match = matchFirst(line, expr);
            if(match) {
                accumulated_code ~= line;
                string opcode = match[1];
                string arg = "";
                if(match.length > 2) {
                    arg = match[2];
                }

                if(accumulated_sequence == "") {
                    accumulated_sequence = opcode;
                }
                else {
                    accumulated_sequence ~= opcode;
                }

                if(this.match_sequences(accumulated_sequence)) {
                    if(this.full_match(accumulated_sequence)) {
                        this.outcode ~= "\t" ~ accumulated_sequence ~ "\n";
                        accumulated_sequence = "";
                        accumulated_code = [];
                    }
                }
                else {
                    this.outcode ~= join(accumulated_code[], "\n") ~ "\n";
                    accumulated_sequence = "";
                    accumulated_code = [];
                }
            }
            else {
                this.outcode ~= line ~ "\n";
                accumulated_sequence = "";
                accumulated_code = [];
            }
        }
    }
}

/**
 * Removes unnecessary push and pull operations
 * where possible
 */

class Remove_stack_ops: Optimization_pass
{
    mixin Optimization_pass_ctor;

    const string[] pushers = [
        "pzero",  "pone", "pbyte", "pword",
        "pwvar", "pbarray", "pbarray_fast", "pwarray", "cmpblt",
        "cmpblte", "cmpbgte", "cmpbeq", "cmpbneq",
        "cmpbgt", "cmpweq", "cmpwneq", "cmpwlt",
        "cmpwgte", "cmpwgt", "cmpwlte", "addb",
        "orb", "andb", "xorb", "mulb", "mulw",
        "divb", "peekb", "peekw", "deek", "inkeyb",
        "inkeyw", "rndb", "rndw", "sqrw"
    ];

    const string[] pullers = [
        "pbarray", "pwarray", "plb2var", "plw2var",
        "plbarray", "plbarray_fast", "plwarray", "cmpblt", "cmpblte",
        "cmpbgte", "cmpbeq", "cmpbneq", "cmpbgt",
        "cmpweq", "cmpwneq", "addb", "orb", "andb",
        "xorb", "mulb", "mulw", "divb", "pokeb",
        "pokew", "doke", "peekb", "peekw", "deek",
        "sys", "usr", "stdlib_printw", "textat", "wat",
        "bat", "ongoto", "ongosub", "sqrw", "wait", "watch"
    ];

    override void run()
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
                this.outcode ~= line ~ "\n";
                continue;
            }

            string next_opc = "";
            string next_line = "";
            if(i+1 < lines.length) {
                int j = i+1;
                do {
                    next_line = lines[j];
                    next_opc = this.get_opc(next_line);
                    j++;
                }
                while(next_line == "");

                if(this.is_puller(opc) && pushf) {
                    if(!pullf) {
                        this.outcode ~= "FPULL\tSET 1\n";
                        pullf = true;
                    }

                }
                else {
                    if(pullf) {
                        this.outcode ~= "FPULL\tSET 0\n";
                        pullf = false;
                    }
                }

                if(this.is_pusher(opc) && this.is_puller(next_opc)) {
                    if(!pushf) {
                        this.outcode ~= "FPUSH\tSET 1\n";
                        pushf = true;
                    }
                }
                else {
                    if(pushf) {
                        this.outcode ~= "FPUSH\tSET 0\n";
                        pushf = false;
                    }
                }
            }

            this.outcode ~= line ~ "\n";
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
        else if(parts.length > 1 && (this.is_puller(parts[1]) || this.is_pusher(parts[1]))) {
            return parts[1];
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
