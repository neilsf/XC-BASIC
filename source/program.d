import std.stdio, std.array, std.conv, std.string, std.file, std.path;
import pegged.grammar;
import core.stdc.stdlib;
import statements;
import basicstdlib;
import nucleus;

struct Variable {
	ushort location;
	string name;
	char type;
	ushort[2] dimensions = [1,1];
	bool isConst = false;
	bool isData = false;
	bool isGlobal = true;
	string procname;

	int constValInt = 0;
	real constValFloat = 0;

	string getLabel()
	{
		if(this.isGlobal) {
			return "_" ~ this.name;
		}
		else {
			return "_" ~ this.procname ~ "." ~ this.name;
		}
	}
}

struct Procedure {
	string name;
	Variable[] arguments;

	string getLabel()
	{
		return "_P" ~ this.name;
	}

	void addArgument(Variable var)
	{
		var.isGlobal = false;
		var.procname = this.name;
		this.arguments ~= var;
	}
}

class Program
{
	struct ProgramSettings {
		ushort heap_start;
		ushort heap_end;
		ushort program_start;
		ushort program_end;
	}

	ProgramSettings settings;

	ubyte[char] varlen;
	char[ubyte] vartype;
	string[char] vartype_names;

	Variable[] variables;
	Variable[] external_variables;
	Variable[] program_data;

	string[] labels;

	Procedure[] procedures;

	ushort stringlit_counter = 0;
	string program_segment;
	string data_segment;

	char last_type;

	ParseTree current_node;

	bool in_procedure = false;
	string current_proc_name = "";

    string source_path = "";
	bool use_floats = true;

	this() {
		/* As of now, vartypes with the same length are not allowed. Needs refactoring if it is a must */
		//this.varlen['b'] = 1; this.vartype[1] = 'b';
		this.varlen['w'] = 2; this.vartype[2] = 'w';
		//this.varlen['s'] = 2; this.vartype[2] = 's';
		this.varlen['f'] = 5; this.vartype[5] = 'f';
		this.settings = ProgramSettings(0xc000, 0xcfff, 0x0801, 0x9999);

		this.vartype_names['w'] = "integer";
		this.vartype_names['s'] = "string";
		this.vartype_names['f'] = "float";
	}

	bool labelExists(string str)
	{
		str = this.in_procedure ? this.current_proc_name ~ "." ~ str : str;
		foreach(ref e; this.labels) {
			if(e == str) {
				return true;
			}
		}

		return false;
	}

	void addLabel(string str)
	{
		str = this.in_procedure ? this.current_proc_name ~ "." ~ str : str;
		if(this.labelExists(str)) {
			this.error("Label "~str~" already defined");
		}

		this.labels ~= str;
	}

	char resolve_sigil(string sigil)
	{
		if(sigil == "" || sigil == "#") {
			return 'w';
		}
		else if(sigil == "$") {
			return 's';
		}
		else if(sigil == "%"){
			return 'f';
		}
		else {
			return 'b';
		}
	}

	string getDataSegment()
	{
		string ret = "data_start:\n";
		ret ~= this.data_segment ~ "data_end:\n";
		return ret;
	}

	string getVarSegment()
	{
		string varsegment;

		varsegment ~= "\t;--------------\n";
		varsegment ~= "\tSEG.U variables\n";
		varsegment ~= "\tORG data_end+1\n";

		foreach(ref variable; this.variables) {
			if(!variable.isData && !variable.isConst) {
				ubyte varlen = this.varlen[variable.type];
				int array_length = variable.dimensions[0] * variable.dimensions[1];
				int total_memory = array_length * this.varlen[variable.type];
				varsegment ~= variable.getLabel() ~"\tDS.B " ~ to!string(total_memory) ~ "\n";
			}
		}

		return varsegment;
	}

	string getCodeSegment()
	{
		string codesegment;
		codesegment ~= "prg_start:\n";
		codesegment ~= "\tinit_program\n";
		codesegment ~= this.program_segment;
		codesegment ~= "prg_end:\n";
		codesegment ~= "\thalt\n";
		return codesegment;
	}

	string getAsmCode()
	{
		string asm_code;

		asm_code ~= "\tPROCESSOR 6502\n\n";
        asm_code ~= "\tINCDIR \""~this.source_path~"\"\n";
		asm_code ~= "\tSEG UPSTART\n";
		asm_code ~= "\tORG $0801\n";
		asm_code ~= "\tDC.W next_line\n";
		asm_code ~= "\tDC.W 2018\n";
		asm_code ~= "\tHEX 9e\n";
		asm_code ~= "\tIF prg_start\n";
		asm_code ~= "\tDC.B [prg_start]d\n";
		asm_code ~= "\tENDIF\n";
		asm_code ~= "\tHEX 00\n";
		asm_code ~= "next_line:\n\tHEX 00 00\n";
		asm_code ~= "\t;--------------------\n";
        asm_code ~= "\tECHO \"Memory information:\"\n";
        asm_code ~= "\tECHO \"===================\"\n";
        asm_code ~= "\tECHO \"BASIC loader: $801 -\", *-1\n";
        asm_code ~= "library_start:\n";
		asm_code ~= nucleus.code;
		asm_code ~= basicstdlib.code;
        asm_code ~= "\tECHO \"Library     :\",library_start,\"-\", *-1\n";

		if(this.use_floats) {
			//asm_code ~= floatlib.code;
		}

		asm_code ~= this.getCodeSegment();
        asm_code ~= "\tECHO \"Code        :\",prg_start,\"-\", *-1\n";
		asm_code ~= this.getDataSegment();
        asm_code ~= "\tECHO \"Data        :\",data_start,\"-\", *-1\n";
		asm_code ~= this.getVarSegment();
        asm_code ~= "\tECHO \"Variables*  :\",data_end,\"-\", *\n";
        asm_code ~= "\tECHO \"===================\"\n";
        asm_code ~= "\tECHO \"*: uninitialized segment\"\n";

		return asm_code;
	}

	ubyte[3] intToBin(int number)
	{
		ubyte[3] data_bytes;
		if(number < 0) {
				number = 16777216 + number;
			}

		try {
			data_bytes[0] = to!ubyte(number >> 16);
			data_bytes[1] = to!ubyte((number & 65280) >> 8);
			data_bytes[2] = to!ubyte(number & 255);
		}
		catch(Exception e) {
			this.error("Compile error: number out of range: "~to!string(number));
		}

		return data_bytes;
	}

	float parseFloat(string strval)
	{
		return to!float(strval);
	}

	int parseInt(string strval)
	{
	  try {
		  if(strval[0] == '$') {
				  return to!int(strval[1..$] ,16);
			  }
			  else if(strval[0] == '%') {
				  return to!int(strval[1..$] ,2);
			  }
			  else {
				  return to!int(strval);
			  }
	  } catch (std.conv.ConvException e) {
		  this.error("Syntax error: '" ~ strval ~"' is not a valid integer literal");
	  }

	  return 0;
	}

	Variable findVariable(string id, string sigil)
	{
        char type = this.resolve_sigil(sigil);

		bool global_mod = id[0] == '\\';
		if(global_mod) {
			id = stripLeft(id, "\\");
		}

		foreach(ref elem; this.variables) {
			if(this.in_procedure && !global_mod) {
				if(elem.name == id && elem.procname == this.current_proc_name && elem.type == type) {
					return elem;
				}
			}
			else {
				if(elem.isGlobal && id == elem.name  && elem.type == type) {
					return elem;
				}
			}
		}

		assert(0);
	}

	Procedure findProcedure(string name)
	{
		foreach(ref elem; this.procedures) {
			if(name == elem.name) {
				return elem;
			}
		}

		assert(0);
	}

	void addVariable(Variable var)
	{
		bool global_mod = var.name[0] == '\\';
		if(global_mod) {
			var.name = stripLeft(var.name, "\\");
		}

		if(this.in_procedure && !global_mod) {
			var.isGlobal = false;
			var.procname = this.current_proc_name;
		}

		this.variables ~= var;
	}

	bool is_variable(string id, string sigil)
	{
        char type = this.resolve_sigil(sigil);

		bool global_mod = (id[0] == '\\');
		if(global_mod) {
			id = stripLeft(id, "\\");
		}

		foreach(ref elem; this.variables) {
			if(this.in_procedure && !global_mod) {
				if(id == elem.name && this.current_proc_name == elem.procname && elem.type == type) {
					return true;
				}
			}
			else {
				if(elem.isGlobal && id == elem.name && elem.type == type) {
					return true;
				}
			}
		}

		return false;
	}

	bool procExists(string name)
	{
		foreach(ref elem; this.procedures) {
			if(elem.name == name) {
				return true;
			}
		}

		return false;
	}

	char guessTheType(string number)
	{
		if(number.indexOfAny(".") > -1) {
			return 'f';
		}

        return 'w';
    }

	void error(string error_message, bool is_warning = false)
	{
		uint error_location = to!uint(this.current_node.begin);
		string partial = this.current_node.input[0..error_location];
		auto lines = splitLines(partial);
		ulong line_no = lines.length + 1;
		stderr.writeln((is_warning ? "WARNING: " : "ERROR: ") ~ error_message ~ " in line " ~ to!string(line_no));
        if(!is_warning) {
            exit(1);
        }
	}

	void warning(string msg)
	{
		this.error(msg, true);
	}

	void processLine(ParseTree node, ubyte pass)
	{
        ParseTree line_id = node.children[0];
        ParseTree statements;
        bool has_statement = false;

        if(node.children.length > 1) {
            statements = node.children[1];
            has_statement = true;
        }

		if(pass == 1) {
			// Check if within procedure
            if(has_statement) {
                if(statements.children[0].children[0].name == "XCBASIC.Proc_stmt") {
                    this.in_procedure = true;
                    this.current_proc_name = join(statements.children[0].children[0].matches);
                }
                else if(statements.children[0].children[0].name == "XCBASIC.Endproc_stmt") {
                    this.in_procedure = false;
                    this.current_proc_name = "";
                }
                // line has statement and it's a DATA statement
                if(statements.children[0].children[0].name == "XCBASIC.Data_stmt") {
                    Stmt stmt = StmtFactory(statements.children[0], this);
                    stmt.process();
                }
            }

			return;
		}
		else {
			//writeln(node);
			string label_type = line_id.children.length == 0 ? "XCBASIC.none" : line_id.children[0].name;
			switch(label_type) {
				case "XCBASIC.Unsigned":
				string line_no = join(line_id.children[0].matches);
				line_no = this.in_procedure ? this.current_proc_name ~ "." ~ line_no : line_no;
				this.program_segment ~= "_L" ~ line_no ~ ":\n";
				break;

				case "XCBASIC.Label":
				string label = join(line_id.children[0].matches[0..$-1]);
				label = this.in_procedure ? this.current_proc_name ~ "." ~ label : label;
				this.program_segment ~= "_L" ~ label ~ ":\n";
				break;

				default:
				break;
			}

			// line has statement(s) excluding a DATA statement
			if(has_statement && statements.children[0].children[0].name != "XCBASIC.Data_stmt") {
                // process all statements in line
                foreach(ref child; statements.children) {
                    Stmt stmt = StmtFactory(child, this);
                    stmt.process();
                }

			}
		}
	}

	void fetchLabels(ParseTree node)
	{
		this.in_procedure = false;
		this.current_proc_name = "";
		foreach(ref child; node.children[0].children) {

			// empty row?
			if(child.name != "XCBASIC.Line" || child.children.length == 0) {
				continue;
			}

			auto Line_id = child.children[0];
			string label_type = Line_id.children.length == 0 ? "XCBASIC.none" : Line_id.children[0].name;
			switch(label_type) {
				case "XCBASIC.Unsigned":
				string line_no = join(Line_id.children[0].matches);
				this.addLabel(line_no);
				break;

				case "XCBASIC.Label":
				string label = join(Line_id.children[0].matches[0..$-1]);
				this.addLabel(label);
				break;

				default:
				break;
			}

			if(child.children.length > 1) {
				auto Stmt = child.children[1].children[0].children[0];
				if(Stmt.name == "XCBASIC.Proc_stmt") {
					this.in_procedure = true;
					this.current_proc_name = join(Stmt.children[0].matches);
				}
				else if(Stmt.name == "XCBASIC.Endproc_stmt") {
					this.in_procedure = false;
					this.current_proc_name = "";
				}
			}
		}
	}

	void processAst(ParseTree node)
	{
		fetchLabels(node);
		void walkAst(ParseTree node, ubyte pass)
		{
			this.current_node = node;
			switch(node.name) {
				case "XCBASIC.Line":
					this.processLine(node, pass);
					break;

				default:
					foreach(ref child; node.children) {
						walkAst(child, pass);
					}
				break;
			}
		}

		/* pass 1 */
		walkAst(node, 1);

		this.in_procedure = false;
		this.current_proc_name = "";

		/* pass 2 */
		walkAst(node, 2);
	}
}
