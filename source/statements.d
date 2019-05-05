module statements;

import pegged.grammar;
import program;
import std.string, std.conv, std.stdio;
import expression;
import stringliteral;
import number;
import excess;

Stmt StmtFactory(ParseTree node, Program program) {
	string stmt_class =node.children[0].name;
	Stmt stmt;
	switch (stmt_class) {
		case "XCBASIC.Const_stmt":
			stmt = new Const_stmt(node, program);
		break;

		case "XCBASIC.Let_stmt":
			stmt = new Let_stmt(node, program);
		break;

		case "XCBASIC.Print_stmt":
			stmt = new Print_stmt(node, program);
		break;

		case "XCBASIC.Goto_stmt":
			stmt = new Goto_stmt(node, program);
		break;

		case "XCBASIC.Gosub_stmt":
			stmt = new Gosub_stmt(node, program);
		break;

		case "XCBASIC.Return_stmt":
			stmt = new Return_stmt(node, program);
		break;

		case "XCBASIC.End_stmt":
			stmt = new End_stmt(node, program);
		break;

		case "XCBASIC.Rem_stmt":
			stmt = new Rem_stmt(node, program);
		break;

		case "XCBASIC.If_stmt":
			stmt = new If_stmt(node, program);
		break;

		case "XCBASIC.Poke_stmt":
			stmt = new Poke_stmt(node, program);
		break;

		case "XCBASIC.Input_stmt":
			stmt = new Input_stmt(node, program);
		break;

		case "XCBASIC.Dim_stmt":
			stmt = new Dim_stmt(node, program);
		break;

		case "XCBASIC.Charat_stmt":
			stmt = new Charat_stmt(node, program);
		break;

		case "XCBASIC.Textat_stmt":
			stmt = new Textat_stmt(node, program);
		break;

		case "XCBASIC.Data_stmt":
			stmt = new Data_stmt(node, program);
		break;

		case "XCBASIC.For_stmt":
			stmt = new For_stmt(node, program);
		break;

		case "XCBASIC.Next_stmt":
			stmt = new Next_stmt(node, program);
		break;

		case "XCBASIC.Inc_stmt":
			stmt = new Inc_stmt(node, program);
		break;

		case "XCBASIC.Dec_stmt":
			stmt = new Dec_stmt(node, program);
		break;

		case "XCBASIC.Proc_stmt":
			stmt = new Proc_stmt(node, program);
		break;

		case "XCBASIC.Endproc_stmt":
			stmt = new Endproc_stmt(node, program);
		break;

		case "XCBASIC.Call_stmt":
			stmt = new Call_stmt(node, program);
		break;

		case "XCBASIC.Sys_stmt":
			stmt = new Sys_stmt(node, program);
		break;

        case "XCBASIC.Load_stmt":
            stmt = new Load_stmt(node, program);
        break;

        case "XCBASIC.Save_stmt":
            stmt = new Save_stmt(node, program);
        break;

        case "XCBASIC.Origin_stmt":
            stmt = new Origin_stmt(node, program);
        break;

        case "XCBASIC.Incbin_stmt":
            stmt = new Incbin_stmt(node, program);
        break;

		default:
            program.error("Unknown statement "~node.name);
		    assert(0);
	}

	return stmt;
}

template StmtConstructor()
{
	this(ParseTree node, Program program)
	{
		super(node, program);
	}
}

interface StmtInterface
{
	void process();
}

abstract class Stmt:StmtInterface
{
	protected ParseTree node;
	protected Program program;

	this(ParseTree node, Program program)
	{
		this.node = node;
		this.program = program;
	}
}

class Const_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree v = this.node.children[0].children[0];
		ParseTree num = this.node.children[0].children[1];
		string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
		char vartype = this.program.resolve_sigil(sigil);

        Number number = new Number(num, this.program);

        if
        (
            (number.type == 'f' && vartype != 'f') ||
            (vartype == 'f' && number.type != 'f')
        ) {
            this.program.error("Type mismatch");
        }

        if(vartype == 'b' && (number.intval < 0 || number.intval > 255)) {
            this.program.error("Number out of range");
        }

		Variable var = {
			name: varname,
			type: number.type,
			isConst: true,
			constValInt: number.intval,
            constValFloat: number.floatval
		};

		if(!this.program.is_variable(varname, sigil)) {
			this.program.addVariable(var);
		}
		else {
			this.program.error("A variable or constant already exists with that name");
		}
	}
}

class Let_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree v = this.node.children[0].children[0];
        ParseTree ex = this.node.children[0].children[1];
        string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        char vartype = this.program.resolve_sigil(sigil);

        if(!this.program.is_variable(varname, sigil)) {
            this.program.addVariable(Variable(0, varname, vartype));
        }
        Variable var = this.program.findVariable(varname, sigil);
        if(var.isConst) {
            this.program.error("Can't assign value to a constant");
        }
        Expression Ex = new Expression(ex, this.program);

        char extype = Ex.detect_type();

        if
        (
            (extype == 'f' && vartype != 'f') ||
            (vartype == 'f' && extype != 'f')
        ) {
            this.program.error("Type mismatch");
        }

        Ex.eval();
        this.program.program_segment ~= to!string(Ex);

        if(extype == 'b' && vartype == 'w') {
            this.program.program_segment ~= "\tbtow\n";
            this.program.warning("Implicit type conversion");
        }
        else if(extype == 'w' && vartype == 'b') {
            this.program.program_segment ~= "\twtob\n";
            this.program.warning("Integer truncated to byte");
        }

        if(v.children.length > 2) {
            /* any variable can be accessed as an array
            if(var.dimensions[0] == 1 && var.dimensions[1] == 1) {
                this.program.error("Not an array");
            }
            */
            auto subscript = v.children[2];
            if((var.dimensions[1] == 1 && subscript.children.length > 1) || (var.dimensions[1] > 1 && subscript.children.length == 1)) {
                this.program.error("Bad subscript");
            }
            ushort[2] dimensions;
            ubyte i = 0;
            foreach(ref expr; subscript.children) {
                Expression Ex2 = new Expression(expr, this.program);
                Ex2.eval();
                this.program.program_segment ~= to!string(Ex2);

                if(i == 1) {
                    // must multiply with first dimension length
                    this.program.program_segment ~= "\tpword #" ~ to!string(var.dimensions[1]) ~ "\n"
                                                  ~ "\tmulw\n"
                                                  ~ "\taddw\n";
                }

                i++;
            }
            // if not a byte, must multiply with the variable length!
            if(vartype != 'b') {
                this.program.program_segment ~= "\tpword #" ~ to!string(this.program.varlen[vartype]) ~ "\n"
                                          ~ "\tmulw\n" ;
            }

            this.program.program_segment ~= "\tpl" ~ to!string(vartype) ~"array "~ var.getLabel() ~ "\n";
        }
        else {
            this.program.program_segment ~= "\tpl" ~ to!string(vartype) ~ "2var " ~ var.getLabel() ~ "\n";
        }
	}
}

class Dim_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree v = this.node.children[0].children[0];
		string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
		char vartype = this.program.resolve_sigil(sigil);

		ushort[2] dimensions;
		if(v.children.length > 2) {
			auto subscript = v.children[2];

			ubyte i = 0;
			foreach(ref expr; subscript.children) {
                string dim = join(expr.matches);
                int dimlen = 0;

                // Case 1: test for constant
                if(this.program.is_variable(dim, "")) {
                    Variable var = this.program.findVariable(dim, "");
                    if(!var.isConst) {
                        this.program.error("Only numeric constants are accepted as array dimensions");
                    }
                    if(var.type != 'w') {
                        this.program.error("Array dimensions must be integers");
                    }

                    dimlen = var.constValInt;
                }
                // Case 2: test for numeric literal
                else {
                    if(expr.children.length > 1) {
                        this.program.error("Only numeric constants are accepted as array dimensions");
                    }
                    Number num = new Number(expr.children[0].children[0].children[0].children[0], this.program);
                    if(num.type == 'f') {
                        this.program.error("Array dimensions must be integers");
                    }
                    dimlen = num.intval;
                }

				dimensions[i] = to!ushort(dimlen);
				i++;
			}

			if(dimensions[1] == 0) {
				dimensions[1] = 1;
			}
		}
		else {
			dimensions[0]=1;
			dimensions[1]=1;
		}

		if(this.program.is_variable(varname, sigil)) {
			this.program.error("Variable "~varname~" is already defined/used.");
		}

		Variable var = Variable(0, varname, vartype, dimensions);
		this.program.addVariable(var);
	}
}

class Print_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree exlist = this.node.children[0].children[0];
		for(char i=0; i< exlist.children.length; i++) {
			final switch(exlist.children[i].name) {

				case "XCBASIC.Expression":
					auto Ex = new Expression(exlist.children[i], this.program);
					Ex.eval();
                    char type = Ex.detect_type();
					this.program.program_segment ~= to!string(Ex);
                    this.program.program_segment ~= "\tstdlib_print"~ to!string(type) ~"\n";
				break;

				case "XCBASIC.String":
					string str = join(exlist.children[i].matches[1..$-1]);
					Stringliteral sl = new Stringliteral(str, this.program);
					sl.register();
					this.program.program_segment ~= "\tlda #<_S" ~ to!string(Stringliteral.id) ~ "\n";
					this.program.program_segment ~= "\tpha\n";
					this.program.program_segment ~= "\tlda #>_S" ~ to!string(Stringliteral.id) ~ "\n";
					this.program.program_segment ~= "\tpha\n";
					this.program.program_segment ~= "\tstdlib_putstr\n";
				break;
			}
		}

		this.program.program_segment ~= "\tlda #13\n";
		this.program.program_segment ~= "\tjsr KERNAL_PRINTCHR\n";
	}
}

class Textat_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree exlist = this.node.children[0];
		Expression col = new Expression(exlist.children[0], this.program);
		Expression row = new Expression(exlist.children[1], this.program);

        if(col.detect_type() == 'f' || row.detect_type != 'f') {
            this.program.error("Column and row must be bytes or integers");
        }

		col.eval();
        if(col.type == 'b') {
            this.program.program_segment ~="\tbtow\n";
        }
		row.eval();
        if(row.type == 'b') {
            this.program.program_segment ~="\tbtow\n";
        }

		if(exlist.children[2].name == "XCBASIC.Expression") {
			this.program.program_segment ~= to!string(row); // rownum
			// multiply by 40
			this.program.program_segment ~="\tpword #40\n" ~ "\tmulw\n";
			// add column
			this.program.program_segment ~= to!string(col); // colnum
			this.program.program_segment ~= "\taddw\n";
			// add 1024
			this.program.program_segment ~="\tpword #1024\n" ~ "\taddw\n";

			// numeric
			Expression ex = new Expression(exlist.children[2], this.program);
			ex.eval();
			this.program.program_segment ~= to!string(ex) ~ "\n";
			this.program.program_segment ~= "\twordat\n";
		}
		else {
			// string literal
			string str = join(exlist.children[2].matches[1..$-1]);
			Stringliteral sl = new Stringliteral(str, this.program);
			sl.register(false, true);
			// text first
			this.program.program_segment ~= "\tlda #<_S" ~ to!string(Stringliteral.id) ~ "\n";
			this.program.program_segment ~= "\tpha\n";
			this.program.program_segment ~= "\tlda #>_S" ~ to!string(Stringliteral.id) ~ "\n";
			this.program.program_segment ~= "\tpha\n";

			this.program.program_segment ~= to!string(row); // rownum second
			// multiply by 40
			this.program.program_segment ~="\tpword #40\n" ~ "\tmulw\n";
			// add column
			this.program.program_segment ~= to!string(col); // colnum last
			this.program.program_segment ~= "\taddw\n";
			// add 1024
			this.program.program_segment ~="\tpword #1024\n" ~ "\taddw\n";
			this.program.program_segment ~="\ttextat\n";
		}
	}
}

class Goto_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		string lbl = join(this.node.children[0].children[0].matches);
		if(!this.program.labelExists(lbl)) {
			this.program.error("Label "~lbl~" does not exist");
		}

		lbl = this.program.in_procedure ? this.program.current_proc_name ~ "." ~ lbl : lbl;
		this.program.program_segment ~= "\tjmp _L"~lbl~"\n";
	}
}

class Call_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		string lbl = join(this.node.children[0].children[0].matches);
		if(!this.program.procExists(lbl)) {
			this.program.error("Procedure not declared");
		}
		Procedure proc = this.program.findProcedure(lbl);
		if(this.node.children[0].children.length > 1) {
			ParseTree exprlist = this.node.children[0].children[1];
			if(exprlist.children.length != proc.arguments.length) {
				this.program.error("Wrong number of arguments");
			}

			for(ubyte i = 0; i < proc.arguments.length; i++) {
				Expression Ex = new Expression(exprlist.children[i], this.program);
				Ex.eval;
				if(proc.arguments[i].type != Ex.detect_type()) {
					this.program.error("Argument type mismatch");
				}
				this.program.program_segment ~= to!string(Ex);
				char vartype = proc.arguments[i].type;
				string varlabel = proc.arguments[i].getLabel();
				this.program.program_segment ~= "\tpl" ~ to!string(vartype) ~ "2var " ~ varlabel ~ "\n";
			}
		}

		this.program.program_segment ~= "\tjsr " ~ proc.getLabel() ~ "\n";
	}
}

class Gosub_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		string lbl = join(this.node.children[0].children[0].matches);
		if(!this.program.labelExists(lbl)) {
			this.program.error("Label "~lbl~" does not exist");
		}

		lbl = this.program.in_procedure ? this.program.current_proc_name ~ "." ~ lbl : lbl;
		this.program.program_segment ~= "\tjsr _L"~lbl~"\n";
	}
}

class Return_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		this.program.program_segment ~= "\trts\n";
	}
}

class End_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		this.program.program_segment ~= "\thalt\n";
	}
}

class Rem_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		{}
	}
}

class If_stmt:Stmt
{
	mixin StmtConstructor;

	public static ushort counter = 1;

	void process()
	{
		ParseTree[] relations;
		int rel_count = 1;
		bool logop_present = false;

		auto statement = this.node.children[0];
		relations ~= statement.children[0];

		if(statement.children[1].name == "XCBASIC.Logop") {
			relations ~= statement.children[2];
			rel_count++;
			logop_present = true;
		}

		for(int i; i < rel_count; i++) {
			auto e1 = relations[i].children[0];
			string rel = join(relations[i].children[1].matches);
			auto e2 = relations[i].children[2];

			auto Ex1 = new Expression(e1, this.program);
			Ex1.eval();
			auto Ex2 = new Expression(e2, this.program);
			Ex2.eval();

            string exp_type;

            if(Ex1.detect_type() == Ex2.detect_type()) {
                exp_type = to!string(Ex1.type);
            }
            else {
                char common_type = this.program.get_higher_type(Ex1.type, Ex2.type);
                if(Ex1.type != common_type) {
                    Ex1.convert(common_type);
                }
                else {
                    Ex2.convert(common_type);
                }
                exp_type = to!string(common_type);
            }
			this.program.program_segment ~= to!string(Ex1);
			this.program.program_segment ~= to!string(Ex2);

			string rel_type;

			final switch(rel) {
				case "<":
					rel_type = "lt";
					break;

				case "<=":
					rel_type = "lte";
					break;

				case "<>":
					rel_type = "neq";
					break;

				case ">":
					rel_type = "gt";
					break;

				case ">=":
					rel_type = "gte";
					break;

				case "=":
					rel_type = "eq";
					break;
			}

			this.program.program_segment~="\tcmp" ~ exp_type ~rel_type~"\n";
		}

		// relations are evaluated, now the comes logical op if present

		if(logop_present) {
			string logop = join(statement.children[1].matches);
			final switch(logop) {
				case "and":
					this.program.program_segment~="\tandb\n";
				break;

				case "or":
					this.program.program_segment~="\torb\n";
				break;
			}
		}

		int cursor = logop_present ? 3 : 1;
		auto st = statement.children[cursor];
		bool else_present = false;

		ParseTree else_st;

		if(statement.children.length > cursor + 1) {
			else_present = true;
			else_st = statement.children[cursor + 1];
		}

		string ret;
		ret ~= "\tpla\n"
			 ~ "\tbne *+5\n";

		if(else_present) {
			ret ~= "\tjmp _E" ~ to!string(counter)  ~ "\n";
		}
		else {
			ret ~= "\tjmp _J" ~ to!string(counter)  ~ "\n";
		}

		this.program.program_segment~=ret;

        // can be multiple statements
        foreach(ref child; st.children) {
            Stmt stmt = StmtFactory(child, this.program);
            stmt.process();
        }

		// else branch
		if(else_present) {
			this.program.program_segment ~= "\tjmp _J" ~ to!string(counter)  ~ "\n";
			this.program.program_segment ~= "_E" ~to!string(counter)~ ":\n";

            // can be multiple statements
            foreach(ref e_child; else_st.children) {
                Stmt else_stmt = StmtFactory(e_child, this.program);
                else_stmt.process();
            }
		}

		this.program.program_segment ~= "_J" ~to!string(counter)~ ":\n";
		counter++;
	}
}

class Poke_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		auto e1 = this.node.children[0].children[0];
		auto e2 = this.node.children[0].children[1];

		auto Ex1 = new Expression(e1, this.program);
        if(Ex1.detect_type() != 'w') {
            this.program.error("Address must be an integer");
        }
		Ex1.eval();
		auto Ex2 = new Expression(e2, this.program);
        if(Ex2.detect_type() == 'f') {
            this.program.error("Value must not be a float");
        }
        Ex2.eval();

		this.program.program_segment ~= to!string(Ex2); // value first
		this.program.program_segment ~= to!string(Ex1); // address last

		this.program.program_segment~="\tpoke"~to!string(Ex2.type)~"\n";
	}
}

class Charat_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		auto e1 = this.node.children[0].children[0];
		auto e2 = this.node.children[0].children[1];
		auto e3 = this.node.children[0].children[2];

		auto Ex1 = new Expression(e1, this.program);
		Ex1.eval();
        if(Ex1.type == 'b') {
            Ex1.btow();
        }
        else if(Ex1.type == 'f') {
            this.program.error("Row and column must not be floats");
        }

		auto Ex2 = new Expression(e2, this.program);
		Ex2.eval();
        if(Ex2.type == 'b') {
            Ex2.btow();
        }
        else if(Ex2.type == 'f') {
            this.program.error("Row and column must not be floats");
        }
		auto Ex3 = new Expression(e3, this.program);
		Ex3.eval();
        if(Ex3.type == 'f') {
            this.program.error("Screencode must not be a float");
        }

		this.program.program_segment ~= to!string(Ex3); // screencode first
		this.program.program_segment ~= to!string(Ex2); // rownum second
		// multiply by 40
		this.program.program_segment ~="\tpword #40\n" ~ "\tmulw\n";
		// add column
		this.program.program_segment ~= to!string(Ex1); // colnum last
		this.program.program_segment ~= "\taddw\n";
		// add 1024
		this.program.program_segment ~="\tpword #1024\n" ~ "\taddw\n";

		this.program.program_segment~="\tpoke"~to!string(Ex1.type)~"\n";
	}
}

class Input_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree list = this.node.children[0].children[0];
		for(char i=0; i< list.children.length; i++) {
			ParseTree v = list.children[i];
			string varname = join(v.children[0].matches);
            string sigil = join(v.children[1].matches);
			char vartype = this.program.resolve_sigil(sigil);
			if(!this.program.is_variable(varname, sigil)) {
				this.program.variables ~= Variable(0, varname, vartype);
			}
			Variable var = this.program.findVariable(varname, sigil);
			if(var.isConst) {
				this.program.error("Can't INPUT to a constant");
			}
			this.program.program_segment~="\tinput\n";
			this.program.program_segment~="\tplw2var " ~ var.getLabel() ~ "\n";
		}
	}
}

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

		this.program.data_segment ~= var.getLabel();
        if(vartype == 'b' || vartype == 'f') {
            this.program.data_segment ~= "\tDC.B ";
        }
        else {
            this.program.data_segment ~= "\tDC.W ";
        }

        string value;
        ubyte[5] floatbytes;
		for(char i=0; i< list.children.length; i++) {
			ParseTree v = list.children[i];
            Number num = new Number(v, this.program);

            if (i > 0) {
                this.program.data_segment ~= ", ";
            }

            if(vartype == 'f' && num.type !='f' || num.type == 'f' && vartype != 'f') {
                this.program.error("Type mismatch");
            }

            if(vartype == 'b' && num.type == 'w') {
                this.program.error("Number out of range");
            }

            if(vartype == 'b' || vartype == 'w') {
                value = to!string(num.intval);
                this.program.data_segment ~= "#" ~value;
            }
            else {
                floatbytes = excess.float_to_hex(num.floatval);
                this.program.data_segment ~=
                    "#$" ~ to!string(floatbytes[0], 16) ~
                    ", #$" ~ to!string(floatbytes[1], 16) ~
                    ", #$" ~ to!string(floatbytes[2], 16) ~
                    ", #$" ~ to!string(floatbytes[3], 16) ~
                    ", #$" ~ to!string(floatbytes[4], 16);
            }

		}

		this.program.data_segment ~="\n";
	}
}

class For_stmt: Stmt
{
	mixin StmtConstructor;

	void process()
	{
		/* step 1 initialize variable */
		ParseTree v = this.node.children[0].children[0];
		ParseTree ex = this.node.children[0].children[1];
		string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
		char vartype = this.program.resolve_sigil(sigil);

        if(vartype == 'f') {
            this.program.error("Index must not be a float");
        }

		if(!this.program.is_variable(varname, sigil)) {
			this.program.addVariable(Variable(0, varname, vartype));
		}
		Variable var = this.program.findVariable(varname, sigil);
		Expression Ex = new Expression(ex, this.program);
		Ex.eval();
        if(Ex.type == 'f' || (Ex.type == 'w' && vartype == 'b')) {
            this.program.error("Type mismatch");
        }
        else if(Ex.type == 'b' && vartype == 'w') {
            Ex.btow();
        }
		this.program.program_segment ~= to!string(Ex);
		this.program.program_segment ~= "\tpl" ~ to!string(vartype) ~ "2var " ~ var.getLabel() ~ "\n";

		/* step 2 evaluate max_value and push value */
		ParseTree ex2 = this.node.children[0].children[2];
		Expression Ex2 = new Expression(ex2, this.program);
		Ex2.eval();
        if(Ex2.type == 'f' || (Ex2.type == 'w' && vartype == 'b')) {
            this.program.error("Type mismatch");
        }
        else if(Ex2.type == 'b' && vartype == 'w') {
            Ex2.btow();
        }
        this.program.program_segment ~= to!string(Ex2);

		/* step 3 call for */
		this.program.program_segment ~= "\tfor\n";
	}
}

class Next_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree v = this.node.children[0].children[0];
		string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        if(!this.program.is_variable(varname, sigil)) {
            this.program.error("Variable " ~varname~" does not exist");
        }
		Variable var = this.program.findVariable(varname, sigil);

        if(var.type == 'f') {
            this.program.error("Variable "~varname~" is a float");
        }

        this.program.program_segment ~= "\tnext"~to!string(var.type)~" "~var.getLabel()~"\n";
	}
}

class Inc_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree v = this.node.children[0].children[0];
		string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        if(!this.program.is_variable(varname, sigil)) {
            this.program.error("Variable " ~varname~" does not exist");
        }

		Variable var = this.program.findVariable(varname, sigil);

        if(var.type == 'f') {
            this.program.error("INC does not work on floats");
        }

		if(var.isConst) {
			this.program.error(varname ~ " is a constant");
		}

		this.program.program_segment ~= "\tinc"~to!string(var.type)~" "~var.getLabel()~"\n";
	}
}


class Dec_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		ParseTree v = this.node.children[0].children[0];
		string varname = join(v.children[0].matches);
        string sigil = join(v.children[1].matches);
        if(!this.program.is_variable(varname, sigil)) {
            this.program.error("Variable " ~varname~" does not exist");
        }
		Variable var = this.program.findVariable(varname, sigil);

        if(var.type == 'f') {
            this.program.error("DEC does not work on floats");
        }

		if(var.isConst) {
			this.program.error(varname ~ " is a constant");
		}
		this.program.program_segment ~= "\tdec"~to!string(var.type)~" "~var.getLabel()~"\n";
	}
}

class Proc_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		if(this.program.in_procedure) {
			this.program.error("Procedure declaration is not allowed here.");
		}
		this.program.in_procedure = true;

		ParseTree pname = this.node.children[0].children[0];
		string name = join(pname.matches);
		if(this.program.procExists(name)) {
			this.program.error("Procedure already declared");
		}

		this.program.current_proc_name = name;

		Variable[] arguments;

		Procedure proc = Procedure(name);

		if(this.node.children[0].children.length > 1) {
			ParseTree varlist = this.node.children[0].children[1];
			foreach(ref var; varlist.children) {
				Variable argument = Variable(0, join(var.children[0].matches), this.program.resolve_sigil(join(var.children[1].matches)));
				this.program.addVariable(argument);
				proc.addArgument(argument);
			}
		}

		this.program.procedures ~= proc;
		this.program.program_segment ~= "\tjmp " ~ proc.getLabel() ~ "_end\n";
		this.program.program_segment ~= proc.getLabel() ~ ":\n";
	}
}

class Endproc_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		if(!this.program.in_procedure) {
			this.program.error("Not in procedure context");
		}


		Procedure current_proc = this.program.findProcedure(this.program.current_proc_name);

		this.program.program_segment ~= "\trts\n";
		this.program.program_segment ~= current_proc.getLabel() ~"_end:\n";

		this.program.in_procedure = false;
		this.program.current_proc_name = "";
	}
}

class Sys_stmt:Stmt
{
	mixin StmtConstructor;

	void process()
	{
		auto e1 = this.node.children[0].children[0];

		auto Ex1 = new Expression(e1, this.program);
		Ex1.eval();

		this.program.program_segment ~= to!string(Ex1);
		this.program.program_segment~="\tsys\n";
	}
}

class Load_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string filename = join(this.node.children[0].children[0].matches)[1..$-1];
        if(filename == "") {
            this.program.error("Empty string");
        }

        auto sl = new Stringliteral(filename, this.program);
        sl.register();

        auto device_no = new Expression(this.node.children[0].children[1], this.program);
        device_no.eval();
        if(device_no.type == 'f') {
            this.program.error("Argument #2 of LOAD must not be a float");
        }
        else if(device_no.type == 'b') {
            device_no.btow();
        }

        bool fixed_address = false;
        if(this.node.children[0].children.length > 2) {
            auto address = new Expression(this.node.children[0].children[2], this.program);
            address.eval();
            if(address.type != 'w') {
                this.program.error("Argument #3 of LOAD must be an integer");
            }
            this.program.program_segment ~= to!string(address);
            fixed_address = true;
        }

        this.program.program_segment ~= to!string(device_no);
        this.program.program_segment ~= "\tpbyte #" ~ to!string(filename.length) ~ "\n";
        this.program.program_segment ~= "\tlda #<_S" ~ to!string(Stringliteral.id) ~ "\n";
        this.program.program_segment ~= "\tpha\n";
        this.program.program_segment ~= "\tlda #>_S" ~ to!string(Stringliteral.id) ~ "\n";
        this.program.program_segment ~= "\tpha\n";
        this.program.program_segment~="\tload " ~ (fixed_address ? "0" : "1") ~ "\n";
    }
}

class Save_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string filename = join(this.node.children[0].children[0].matches)[1..$-1];
        if(filename == "") {
            this.program.error("Empty string");
        }

        auto sl = new Stringliteral(filename, this.program);
        sl.register();

        auto device_no = new Expression(this.node.children[0].children[1], this.program);
        device_no.eval();
        if(device_no.type == 'f') {
            this.program.error("Argument #2 of SAVE must not be a float");
        }
        else if(device_no.type == 'b') {
            device_no.btow();
        }

        auto address1 = new Expression(this.node.children[0].children[2], this.program);
        address1.eval();
        if(address1.type != 'w') {
            this.program.error("Argument #3 of SAVE must be an integer");
        }

        auto address2 = new Expression(this.node.children[0].children[3], this.program);
        address2.eval();
        if(address2.type != 'w') {
            this.program.error("Argument #4 of SAVE must be an integer");
        }

        this.program.program_segment ~= to!string(address2);
        this.program.program_segment ~= to!string(address1);
        this.program.program_segment ~= to!string(device_no);
        this.program.program_segment ~= "\tpbyte #" ~ to!string(filename.length) ~ "\n";
        this.program.program_segment ~= "\tlda #<_S" ~ to!string(Stringliteral.id) ~ "\n";
        this.program.program_segment ~= "\tpha\n";
        this.program.program_segment ~= "\tlda #>_S" ~ to!string(Stringliteral.id) ~ "\n";
        this.program.program_segment ~= "\tpha\n";
        this.program.program_segment ~= "\tsave\n";
    }
}

class Origin_stmt:Stmt
{
    mixin StmtConstructor;

    void process()
    {
        string num = join(this.node.children[0].children[0].matches);
        this.program.program_segment~="\torg "~num~"\n";
    }
}

class Incbin_stmt:Stmt
{
    mixin StmtConstructor;

    static int counter = 0;

    void process()
    {
        Incbin_stmt.counter+=1;
        string lblc = to!string(Incbin_stmt.counter);
        string incfile = join(this.node.children[0].children[0].matches);
        this.program.program_segment~="_IJS"~lblc~"\tINCBIN "~incfile~"\n";
        this.program.program_segment~="_IJ"~lblc~"\n";
        this.program.program_segment~= "\tECHO \"Included file ("~replace(incfile,"\"", "")~"):\",_IJS"~lblc~",\"-\", _IJ"~lblc~"\n";
    }
}
