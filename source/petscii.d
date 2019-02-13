import std.string, std.conv;
import std.regex;

char[] petscii = [
    0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf,
    0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    ' ', '!', '"', '#', '$', '%', '&', '\'', '(', ')', '*', '+', ',', '-', '.', '/',
    '0', '1', '2', '3', '4', '5', '6', '7' , '8', '9', ':', ';', '<', '=', '>', '?',
    '@', 'a', 'b', 'c', 'd', 'e', 'f', 'g' , 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o',
    'p', 'q', 'r', 's', 't', 'u', 'v', 'w' , 'x', 'y', 'z', '[', '\x5c', ']', '\x5e', '\x5f',
    '\x60', 'A', 'B', 'C', 'D', 'E', 'F', 'G' , 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
    'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W' , 'X', 'Y', 'Z', '\x7b', '\x7c', '\x7d', '\x7e', '\x7f',
    0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
    0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
    0xa0, 0xa1, 0xa2, 0xa3, 0xa4, 0xa5, 0xa6, 0xa7, 0xa8, 0xa9, 0xaa, 0xab, 0xac, 0xad, 0xae, 0xaf,
    0xb0, 0xb1, 0xb2, 0xb3, 0xb4, 0xb5, 0xb6, 0xb7, 0xb8, 0xb9, 0xba, 0xbb, 0xbc, 0xbd, 0xbe, 0xbf,  
    0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7, 0xc8, 0xc9, 0xca, 0xcb, 0xcc, 0xcd, 0xce, 0xcf,  
    0xd0, 0xd1, 0xd2, 0xd3, 0xd4, 0xd5, 0xd6, 0xd7, 0xd8, 0xd9, 0xda, 0xdb, 0xdc, 0xdd, 0xde, 0xdf,  
    0xe0, 0xe1, 0xe2, 0xe3, 0xe4, 0xe5, 0xe6, 0xe7, 0xe8, 0xe9, 0xea, 0xeb, 0xec, 0xed, 0xee, 0xef,  
    0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff
];

ubyte ascii_to_petscii(char ascii_char)
{
    for(ubyte i=0; i<=0xff; i++) {
        if(petscii[i] == ascii_char) {
            return i;
        }
    }

    return 0;
}

string replace_petscii_escapes(string s)
{
    string ret;
    ret = tr(s,     "{CLR}", "\x93");
    ret = tr(ret,   "{HOME}", "\x13");
    ret = tr(ret,   "{INSERT}", "\x94");
    ret = tr(ret,   "{DEL}", "\x14");
    ret = tr(ret,   "{CR}", "\x0d");
    ret = tr(ret,   "{REV_ON}", "\x12");
    ret = tr(ret,   "{REV_OFF}", "\x92");
    ret = tr(ret,   "{CRSR_UP}", "\x91");
    ret = tr(ret,   "{CRSR_DOWN}", "\x11");
    ret = tr(ret,   "{CRSR_LEFT}", "\x9d");
    ret = tr(ret,   "{CRSR_RIGHT}", "\x1d");

    return ret;
}

 char[] replace_numeric_escapes(string s) {
    char[] r;
    bool esc = false;
    ubyte chr=0;
    string num = "";
    for (ubyte i=0; i < s.length; i++) {
        if(!esc && s[i] != '{' && s[i] != '}') {
            r ~= s[i];
        }
        else if(s[i] == '{') {
            esc = true;
        }
        else if(s[i] == '}') {
            r ~= to!ubyte(num);
            esc = false;
            num = "";
        }
        else {
            num = num ~ to!string(s[i]);
        }
    }
    
    return r;
}

string str_ascii_to_petscii(string ascii_string)
{
    string petscii_string = replace_petscii_escapes(ascii_string.dup);
    /*
    for(ubyte i=0; i<ascii_string.length; i++) {
        petscii_string[i] = ascii_to_petscii(ascii_string[i]);
    }
    */
    return to!string(petscii_string);
}

string ascii_to_petscii_hex(string ascii_string, bool newline = true)
{
    string hex = "";
    for(ubyte i=0; i<ascii_string.length; i++) {
        hex ~= to!string(ascii_to_petscii(ascii_string[i]), 16) ~ " ";
    }
    if(newline) {
        hex ~= "0D ";    
    }
    hex ~= "00";
    return hex;
}

string ascii_to_screencode_hex(string ascii_string)
{
    string hex = "";
    for(ubyte i=0; i<ascii_string.length; i++) {
        hex ~= rightJustify(to!string(petscii_to_screencode(ascii_to_petscii(ascii_string[i])), 16), 2, '0') ~ " ";
    }
    hex ~= "00";
    return hex;
}

int petscii_to_screencode(ubyte petscii_code)
{
    if(petscii_code < 32) {
        return petscii_code + 128;
    }

    if(petscii_code < 64) {
        return petscii_code;
    }

    if(petscii_code < 96) {
        return petscii_code - 64;
    }

    if(petscii_code < 128) {
        return petscii_code - 32;
    }

    if(petscii_code < 160) {
        return petscii_code + 64;
    }

    if(petscii_code < 192) {
        return petscii_code - 64;
    }

    if(petscii_code < 255) {
        return petscii_code - 128;
    }

    return petscii_code - 94;
}
