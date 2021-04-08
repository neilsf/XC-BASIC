module optimizer;

import std.string, std.array, std.uni, std.regex, std.stdio;
import std.algorithm;
import library.opt;

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

class Optimizer: Optimization_pass
{
    string incode;
    string outcode;

    mixin Optimization_pass_ctor;

    override void run()
    {
        string code;
        auto op1 = new Replace_sequences(this.incode);
        op1.run();
        auto op2 = new Remove_stack_ops(op1.outcode);
        op2.run();
        this.outcode = op2.outcode;
    }
}



/**
 * Replaces sequences of pseudo-ops with
 * equivalent but faster ones
 */

class Replace_sequences: Optimization_pass
{
    mixin Optimization_pass_ctor;

    string[string] sequences;

    struct op_code {
        string op;
        string arg;
    }

    private void fetch_sequences()
    {
        string[] lines = splitLines(library.opt.code);
        bool fetch = false;
        string macname;
        foreach(line; lines) {
            if(line == "\t; [OPT_MACRO]") {
                fetch = true;
                continue;
            }

            if(line == "\t; [/OPT_MACRO]") {
                fetch = false;
                continue;
            }

            if(!fetch) {
                continue;
            }

            auto expr = regex(r"\tMAC\s([a-z_]+)");
            auto match = matchFirst(line, expr);
            if(match) {
                macname = match[1];
                continue;
            }

            expr = regex(r"\t;\s\>\s([a-z0-9_\+]+)");
            match = matchFirst(line, expr);
            if(match) {
                this.sequences[match[1]] = macname;
                continue;
            }
        }
    }

    private bool match_sequences(string candidate)
    {
        uint len = cast(uint)candidate.length;
        foreach(item; this.sequences.byKey()) {
            if(len <= item.length && item[0..len] == candidate) {
                return true;
            }
        }
        return false;
    }

    private bool full_match(string candidate)
    {
        foreach(item; this.sequences.byKey()) {
            if(item == candidate) {
                return true;
            }
        }
        return false;
    }

    private string stringify_sequence(op_code[] sequence)
    {
        string retval = "";
        for(int i = 0; i < sequence.length; i++) {
            if(i > 0) {
                retval ~= "+";
            }
            retval ~= sequence[i].op;
        }
        return retval;
    }

    private string stringify_args(op_code[] sequence)
    {
        string retval = "";
        bool first = true;
        for(int i = 0; i < sequence.length; i++) {
            if(sequence[i].arg != "") {
                if(!first) {
                    retval ~= ", ";
                }
                retval ~= sequence[i].arg;
                first = false;
            }
        }
        return retval;
    }

    private bool replace_seqs()
    {
        bool opt_enabled = false;
        bool replacements_made = false;
        string[] lines = splitLines(this.incode);
        op_code[] accumulated_sequence;
        string[] accumulated_code;

        this.outcode = "";
        for(int i=0; i<lines.length; i++) {
            string line = lines[i];

            if(line.length == 0) {
                continue;
            }

            if(line == "\t; !!opt_start!!") {
                opt_enabled = true;
                this.outcode ~= line ~ "\n";
                continue;
            }
            else if(line == "\t; !!opt_end!!") {
                opt_enabled = false;
                this.outcode ~= join(accumulated_code, "\n") ~ "\n" ~ line ~ "\n";
                accumulated_sequence = [];
                accumulated_code = [];
                this.outcode ~= line ~ "\n";
                continue;
            }

            if(!opt_enabled) {
                this.outcode ~= line ~ "\n";
                continue;
            }

            auto expr = regex(r"\t([a-z0-9_]+)(\s.+)?");
            auto match = matchFirst(line, expr);
            if(match) {
                accumulated_code ~= line;
                string opcode = match[1];
                string arg = "";
                if(match.length > 2) {
                    arg = match[2];
                }

                op_code op = {opcode, arg};
                accumulated_sequence ~= op;
                string seqstring = this.stringify_sequence(accumulated_sequence);

                if(this.match_sequences(seqstring)) {
                    //stderr.writeln("match: " ~ seqstring);
                    if(this.full_match(seqstring)) {
                        //stderr.writeln("full match: " ~ seqstring);
                        this.outcode ~= "\t" ~ this.sequences[seqstring] ~ " " ~ this.stringify_args(accumulated_sequence) ~ "\n";
                        accumulated_sequence = [];
                        accumulated_code = [];
                        replacements_made = true;
                    }
                }
                else {
                    //stderr.writeln("no match: " ~ seqstring);
                    this.outcode ~= accumulated_code[0] ~ "\n";
                    accumulated_sequence = accumulated_sequence.remove(0);
                    accumulated_code = accumulated_code.remove(0);
                }
            }
            else {
                this.outcode ~= join(accumulated_code, "\n") ~ "\n" ~ line ~ "\n";
                accumulated_sequence = [];
                accumulated_code = [];
            }
        }

        return replacements_made;
    }

    override void run()
    {
        this.fetch_sequences();
        bool success;
        this.replace_seqs();
        do {
            success = this.replace_seqs();
            if(success) {
                this.incode = this.outcode;
            }
        }
        while(success);
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
        "pzero",  "pone", "pbyte", "pbvar", "pword", "paddr",
        "pwvar", "psvar", "pbarray", "pbarray_fast", "pwarray", "psarray", "cmpblt",
        "cmpblte", "cmpbgte", "cmpbeq", "cmpbneq",
        "cmpbgt", "cmpweq", "cmpwneq", "cmpwlt",
        "cmpwgte", "cmpwgt", "cmpwlte", "addb",
        "orb", "andb", "xorb", "mulb", "mulw",
        "divb", "divw", "peekb", "peekw", "deek", "inkeyb",
        "inkeyw", "rndb", "rndw", "sqrw",
        "opt_pbyte_pbyte_add", "opt_pword_pwvar_add", "opt_pwvar_pword_add",
        "opt_pwvar_pwvar_add", "opt_pbyte_pbyte_sub", "opt_pword_pwvar_sub",
        "opt_pwvar_pword_sub", "opt_pwvar_pwvar_sub", "opt_pbyte_pbarray_fast",
        "pbyte_pbyte_cmpbeq", "pbyte_pbyte_cmpbneq", "pbyte_pbyte_cmpblt", "pbyte_pbyte_cmpblte",
        "pbyte_pbyte_cmpbgt", "pbyte_pbyte_cmpbgte", "peekw_const_addr", "peekb_const_addr",
        "opt_pbyte_pbyte_or", "opt_pbyte_pbyte_and", "opt_pbyte_pbyte_xor",
        "lshiftb", "rshiftb", "rshiftbc", "lshiftbc"
    ];

    const string[] pullers = [
        "pbarray", "pbarray_fast", "pwarray", "psarray", "plb2var", "plw2var", "pls2var",
        "plbarray", "plbarray_fast", "plwarray", "plsarray" , "plfarray", "cmpblt", "cmpblte",
        "cmpbgte", "cmpbeq", "cmpbneq", "cmpbgt",
        "cmpweq", "cmpwneq", "addb", "orb", "andb",
        "xorb", "mulb", "mulw", "divb", "divw", "pokeb",  "pokeb_c",
        "pokew", "pokew_c", "doke", "peekb", "peekw", "deek",
        "sys", "usr", "stdlib_printw", "textat", "wat",
        "bat", "printb", "printw", "ongoto", "ongosub", "sqrw", "wait", "watch", "watchc",
        "pokeb_const_addr", "poke_const_addr",
        "cond_stmt", "prints", "lshiftb", "rshiftb", "lshiftw", "rshiftw",
        "lshiftbc", "rshiftbc", "incbarrb", "incwarr", "decbarrb", "decwarr", "incbarr", "decbarr"
    ];

    override void run()
    {
        this.outcode = "";
        string[] lines = splitLines(this.incode);
        bool opt_enabled = false;
        bool pushf = false;
        bool pullf = false;

        bool lineIsLabel(string line) {
            return line.length > 2 && line[$-1] == ':';
        }

        bool lineIsComment(string line) {
            string stripped = stripLeft(line);
            return stripped.length > 0 && stripped[0] == ';';
        }

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

            if(lineIsLabel(line) || lineIsComment(line)) {
                this.outcode ~= line ~ "\n";
                continue;
            }

            string opc = this.get_opc(line);
            
            string next_opc = "";
            string next_line = "";
            if(i+1 < lines.length) {
                int j = i+1;
                do {
                    next_line = lines[j];
                    next_opc = this.get_opc(next_line);
                    j++;
                }
                while(next_line == "" || lineIsLabel(next_line) || lineIsComment(line));

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
        string[] allparts = line.split!isWhite;
        string[] parts;
        foreach (string part; allparts) {
            if(part.length > 0) {
                parts ~= part;
            }
        }

        if(parts.length == 0) {
            return "";
        }

        if(this.is_puller(parts[0]) || this.is_pusher(parts[0])) {
            return parts[0];
        }
        else if(parts.length > 1 && (this.is_puller(parts[1]) || this.is_pusher(parts[1]))) {
            return parts[1];
        }
        else {
            return parts[0];
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
