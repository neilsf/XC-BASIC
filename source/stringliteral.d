module stringliteral;

import program;
import std.conv;
import petscii;

class Stringliteral
{
    public static ushort id = 0;
    Program program;
    string str;

    this(string str, Program program)
    {
        Stringliteral.id += 1;
        this.program = program;
        this.str = str;
    }

    void register(bool newline = false, bool generate_screencodes = false)
    {
        string data;
        if(generate_screencodes) {
            data = ascii_to_screencode_hex(this.str);
        }
        else {
            data = ascii_to_petscii_hex(this.str, newline);
        }
        this.program.data_segment ~= "_S" ~ to!string(Stringliteral.id) ~ "\t" ~ data ~ "\n";
    }
}
