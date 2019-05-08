module excess;

import std.math;
import std.conv;
import std.stdio;
import std.string;
import std.array;
import core.stdc.stdlib;

ubyte[5] float_to_hex(real value) {

    if(value == 0) {
        return [0u, 0u, 0u, 0u, 0u];
    }

  string toBinary(real fraction) {
      real exp = -1;
      const int precision = 32;
      real div;
      real mod;
      string result = "";

      if(fraction == 0) {
          return "0";
      }

      while(fraction > 0 && (-exp <= precision)) {
          div = floor(fraction / pow(2,exp));
          mod = fraction - div * pow(2,exp);
          result ~= to!string(div);
          fraction = mod;
          exp -= 1;
      }

      return result;
  }

  bool is_negative;
  is_negative = value < 0;
  int exponent=0;
  string m1, m2, m3, m4, mantstring;

  value = abs(value);
  real result = value;

    if(value < 0.5) {
        while(result < 0.5) {
            result = result*2;
            exponent--;
        }
    }
    else {
        while(result >= 1) {
            result = result/2;
            exponent++;
        }
    }

    exponent = exponent + 128;
    real mantissa = result;
    string binary_fraction = toBinary(mantissa);

    int pad_digits = 0;
    if(binary_fraction.length < 32) {
        pad_digits = 32 - to!int(binary_fraction.length);
    }
    mantstring = binary_fraction ~ ("0".replicate(pad_digits));
    mantstring = (is_negative ? '1' : '0') ~ mantstring[1..32];

    m4 = mantstring[0..8];
    m3 = mantstring[8..16];
    m2 = mantstring[16..24];
    m1 = mantstring[24..32];

    return [to!ubyte(exponent),
        to!ubyte(to!int(m4,2)),
        to!ubyte(to!int(m3,2)),
        to!ubyte(to!int(m2,2)),
        to!ubyte(to!int(m1,2))
    ];
}

