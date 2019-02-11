module excess;

import std.math;
import std.conv;
import std.stdio;
import std.string;
import std.array;

ubyte[4] float_to_hex(real value) {
    string toBinary(real fraction) {
      real exp = -1;
      int precision = 22;
      real div;
      real mod;
      string result = "";

      if(fraction == 0) {
          return "0";
      }

      while(fraction > 0 && (-exp <= precision)) {
          div = floor(fraction / pow(2.0,exp));
          mod = fraction - div * pow(2.0,exp);
          result ~= to!string(div);
          fraction = mod;
          exp -= 1;
      }

      return result;
    }
    int getExponent(real value) {
        real result;
        int exp = 0;
        if(value < 1) {
            for(int x=0; x>=-128; x--) {
                result = value / pow(2.0, x);
                if(result <2 && result >=1) {
                    exp = x;
                    break;
                }
            }
        }
        else {
            for(int x=0; x<=127; x++) {
                result = value / pow(2.0, x);
                if(result <2 && result >=1) {
                    exp = x;
                    break;
                }
            }
        }

        return exp;
    }

    immutable bool negative = value < 0;
    value = abs(value);

    immutable int exp = getExponent(value);

    real mant = value/pow(2.0, exp);
    string mantsign = "0";
    if(negative) {
        mantsign = "1";
    }
    immutable int whole_of_mant = to!int(floor(mant));
    mant = mant-whole_of_mant;

    string binary_fraction = toBinary(mant);
    string mantstr = to!string(whole_of_mant) ~ binary_fraction ~ ("0".replicate(23 - (1 + binary_fraction.length)));
    string final_mantstr = "";
    if(negative) {
        for(int l=0; l<23; l++) {
            if(mantstr[l] == '1') {
                final_mantstr ~= '0';
            }
            else {
                final_mantstr ~= '1';
            }
        }
    }
    else {
        final_mantstr = mantstr;
    }

    final_mantstr = mantsign ~ final_mantstr;

    ubyte[4] ret;

    string mant1 = final_mantstr[0..8];
    string mant2 = final_mantstr[8..16];
    string mant3 = final_mantstr[16..24];

    writeln(mant1 ~ " " ~ mant2 ~ " " ~ mant3);

    ret[0] = to!ubyte(exp+128);
    ret[1] = to!ubyte(mant1, 2);
    ret[2] = to!ubyte(mant2, 2);
    ret[3] = to!ubyte(mant3, 2);

    return ret;
}

