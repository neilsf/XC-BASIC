module statement.data_stmt;

import std.conv, std.string;

import pegged.grammar;

import language.statement;
import language.excess;
import language.expression;
import language.number;
import language.stringliteral;

import program;

class Data_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string varname = join(this.node.children[0].children[0].matches);
        string sigil = join(this.node.children[0].children[1].matches);
        char vartype = this.program.resolve_sigil(sigil);
        ParseTree list = this.node.children[0].children[2];
        ushort dimension = to!ushort(list.children.length);

        if(!this.program.is_variable(varname, sigil)) {
            this.program.addVariable(Variable(0, varname, vartype, [dimension, 1], false, true));
        }
        Variable var = this.program.findVariable(varname, sigil);

        if(var.isConst) {
            this.program.error(varname ~ " is a constant");
        }

        if(list.name == "XCBASIC.Datalist") {
            string seg = "";
            seg ~= var.getLabel();
            if(vartype == 'w' || vartype == 's') {
                seg ~= "\tDC.W ";
            }
            else {
                seg ~= "\tDC.B ";
            }

            string value;
            ubyte[5] floatbytes;
            ubyte counter = 0;
            for(int i=0; i< list.children.length; i++) {
                ParseTree v = list.children[i];
                if (counter > 0) {
                    seg ~= ", ";
                }
                final switch(v.name) {
                    case "XCBASIC.Number":

                        Number num = new Number(v, this.program);
                        // Strings not allowed here
                        // Floats and other types may not be mixed
                        if(vartype == 's' || (vartype == 'f' && num.type !='f') || (num.type == 'f' && vartype != 'f')) {
                            this.program.error("Type mismatch");
                        }

                        if(vartype == 'b' && num.type == 'w' || vartype == 'w' && num.type == 'l') {
                            this.program.error("Number out of range");
                        }

                        if(vartype == 'b' || vartype == 'w') {
                            value = to!string(num.intval);
                            seg ~= "#" ~value;
                        }
                        else if(vartype == 'l') {
                            value = num.get_hex_of_long();
                            seg ~=  "#$" ~ value[0..2] ~
                                    ", #$" ~ value[2..4] ~
                                    ", #$" ~ value[4..6];
                        }
                        else {
                            floatbytes = language.excess.float_to_hex(num.floatval);
                            seg ~=
                                "#$" ~ to!string(floatbytes[0], 16) ~
                                ", #$" ~ to!string(floatbytes[1], 16) ~
                                ", #$" ~ to!string(floatbytes[2], 16) ~
                                ", #$" ~ to!string(floatbytes[3], 16) ~
                                ", #$" ~ to!string(floatbytes[4], 16);
                        }
                    break;

                    case "XCBASIC.String":
                        if(vartype != 's') {
                            this.program.error("Type mismatch");
                        }
                        string str = join(v.matches[1..$-1]);
                        Stringliteral sl = new Stringliteral(str, this.program);
                        sl.register();
                        seg ~= "_S" ~ to!string(Stringliteral.id);
                    break;
                }

                counter++;
                if(counter == 16 && i < list.children.length-1) {
                    seg ~= "\n";
                    if(vartype == 'w' || vartype == 's') {
                        seg ~= "\tDC.W ";
                    }
                    else {
                        seg ~= "\tDC.B ";
                    }
                    counter = 0;
                }
            }

            this.program.data_segment ~= seg ~ "\n";
        }
        else {
            if(vartype != 'b') {
                this.program.error("Included binary files may only be assigned to byte type arrays");
            }
            this.program.data_segment ~= var.getLabel() ~ ":\n\tINCBIN "~join(list.children[0].matches)~"\n";
        }
    }
}
