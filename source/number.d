module number;

import std.conv;
import std.string;
import pegged.grammar;
import program;

class Number
{
    ParseTree node;
    Program program;
    string str_repr;
    int intval;
    real floatval;
    char type;

    this(ParseTree node, Program program)
    {
        this.str_repr = str_repr;
        this.program = program;

        string num_str = join(node.children[0].matches);
        final switch(node.children[0].name) {
            case "XCBASIC.Integer":
                int num = to!int(num_str);
                if(num < -32768 || num > 65535) {
                    this.program.error("Number out of range");
                }
                this.intval = num;
                this.type = 'w';
                break;

            case "XCBASIC.Hexa":
                num_str = num_str[1..$];
                int num = to!int(num_str, 16);
                if(num > 65535) {
                    this.program.error("Number out of range");
                }
                this.intval = num;
                this.type = 'w';
                break;

            case "XCBASIC.Binary":
                num_str = num_str[1..$];
                int num = to!int(num_str, 2);
                if(num > 65535) {
                    this.program.error("Number out of range");
                }
                this.intval = num;
                this.type = 'w';
                break;

            case "XCBASIC.Floating":
                try {
                    this.floatval = to!real(num_str);
                    this.type = 'f';
                }
                catch(Exception e) {
                    this.program.error("Can't parse number "~num_str);
                }
                break;
        }
    }
}
