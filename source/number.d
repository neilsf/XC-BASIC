module number;

import std.conv;
import std.string;

class Number
{
    string str_repr;

    this(string str_repr)
    {
        this.str_repr = str_repr;
    }

    char detect_type()
    {
        return 'i';
    }

    int get_intval()
    {
        if(str_repr[0] == '$') {
            return to!int(str_repr[1..$], 16);
        }
        else {
            return to!int(str_repr);
        }
    }

    real get_floatval()
    {
        return 0.0;
    }
}
