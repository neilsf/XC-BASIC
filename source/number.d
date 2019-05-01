module number;

import std.conv;
import std.string;
import program;
import pegged.grammar;

class Number
{
    char type;
    int intval;
    real floatval;

    this(ParseTree node, Program program)
    {
        bool is_float = false;
        string textual = join(node.matches);
        if(textual[0] == '$') {
            this.intval = to!int(textual[1..$], 16);
        }
        else if(textual[0] == '%') {
            this.intval = to!int(textual[1..$], 2);
        }
        else {
            if(std.string.indexOf(textual, '.') == -1) {
                this.intval = to!int(textual);
            }
            else {
                is_float = true;
                try {
                    this.floatval = to!real(textual);
                }
                catch(Exception e) {
                    program.error("Unable to parse number "~textual);
                }
            }
        }

        this.type = is_float ? 'f' : 'w';

        if(this.type == 'w' && (this.intval < -32767 || this.intval > 65535)) {
            program.error("Number out of range");
        }
    }
}
