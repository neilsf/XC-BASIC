module statement.incbin_stmt;

import std.conv, std.string, std.file, std.path, std.stdio;
import pegged.grammar;
import language.statement;
import program;

class Incbin_stmt:Stmt
{
    mixin StmtConstructor;

    static int counter = 0;

    void process()
    {
        Incbin_stmt.counter+=1;
        string lblc = to!string(Incbin_stmt.counter);
        string incfile = join(this.node.children[0].children[0].matches);
        string incfile_noquotes = incfile[1..$-1];
        string full_path = this.program.source_path ~ dirSeparator ~ incfile_noquotes;
        try {
            File f = File(full_path);
        }
        catch(Exception e) {
            this.program.error("File cannot be read: "~full_path);
        }
        this.program.program_segment~="_IJS"~lblc~"\tINCBIN "~incfile~"\n";
        this.program.program_segment~="_IJ"~lblc~"\n";
        this.program.program_segment~= "\tECHO \"Included file ("~replace(incfile,"\"", "")~"):\",_IJS"~lblc~",\"-\", _IJ"~lblc~"\n";
    }
}
