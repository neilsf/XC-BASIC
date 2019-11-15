module language.statement;

import pegged.grammar;
import program;
import std.string, std.conv, std.stdio, std.file, std.path;
import language.expression;
import language.stringliteral;
import language.number;
import language.excess;
import language.xcbarray;
import language.condition;

import statement.asm_stmt;
import statement.call_stmt;
import statement.charat_stmt;
import statement.const_stmt;
import statement.curpos_stmt;
import statement.data_stmt;
import statement.dec_stmt;
import statement.dim_stmt;
import statement.disableirq_stmt;
import statement.doke_stmt;
import statement.else_stmt;
import statement.enableirq_stmt;
import statement.end_stmt;
import statement.endfun_stmt;
import statement.endif_stmt;
import statement.endproc_stmt;
import statement.endwhile_stmt;
import statement.for_stmt;
import statement.fun_stmt;
import statement.if_stmt;
import statement.inc_stmt;
import statement.incbin_stmt;
import statement.input_stmt;
import statement.gosub_stmt;
import statement.goto_stmt;
import statement.let_stmt;
import statement.load_stmt;
import statement.memcpy_stmt;
import statement.memset_stmt;
import statement.memshift_stmt;
import statement.next_stmt;
import statement.on_stmt;
import statement.origin_stmt;
import statement.poke_stmt;
import statement.pragma_stmt;
import statement.print_stmt;
import statement.proc_stmt;
import statement.rem_stmt;
import statement.return_stmt;
import statement.return_fn_stmt;
import statement.repeat_stmt;
import statement.save_stmt;
import statement.sys_stmt;
import statement.strcpy_stmt;
import statement.strncpy_stmt;
import statement.textat_stmt;
import statement.until_stmt;
import statement.wait_stmt;
import statement.watch_stmt;
import statement.while_stmt;


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

        case "XCBASIC.Doke_stmt":
            stmt = new Doke_stmt(node, program);
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

        case "XCBASIC.Fun_stmt":
            stmt = new Fun_stmt(node, program);
        break;

		case "XCBASIC.Endproc_stmt":
			stmt = new Endproc_stmt(node, program);
		break;

        case "XCBASIC.Endfun_stmt":
            stmt = new Endfun_stmt(node, program);
        break;

		case "XCBASIC.Call_stmt":
        case "XCBASIC.Userdef_cmd":
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

        case "XCBASIC.Include_stmt":
            stmt = new Rem_stmt(node, program);
        break;

        case "XCBASIC.Asm_stmt":
            stmt = new Asm_stmt(node, program);
        break;

        case "XCBASIC.Strcpy_stmt":
            stmt = new Strcpy_stmt(node, program);
        break;

        case "XCBASIC.Strncpy_stmt":
            stmt = new Strncpy_stmt(node, program);
        break;

        case "XCBASIC.Curpos_stmt":
            stmt = new Curpos_stmt(node, program);
        break;

        case "XCBASIC.On_stmt":
            stmt = new On_stmt(node, program);
        break;

        case "XCBASIC.Wait_stmt":
            stmt = new Wait_stmt(node, program);
        break;

        case "XCBASIC.Watch_stmt":
            stmt = new Watch_stmt(node, program);
        break;

        case "XCBASIC.Pragma_stmt":
            stmt = new Pragma_stmt(node, program);
        break;

        case "XCBASIC.Memset_stmt":
            stmt = new Memset_stmt(node, program);
        break;

        case "XCBASIC.Memcpy_stmt":
            stmt = new Memcpy_stmt(node, program);
        break;

        case "XCBASIC.Memshift_stmt":
            stmt = new Memshift_stmt(node, program);
        break;

        case "XCBASIC.While_stmt":
            stmt = new While_stmt(node, program);
        break;

        case "XCBASIC.Endwhile_stmt":
            stmt = new Endwhile_stmt(node, program);
        break;

        case "XCBASIC.Repeat_stmt":
            stmt = new Repeat_stmt(node, program);
        break;

        case "XCBASIC.Until_stmt":
            stmt = new Until_stmt(node, program);
        break;

        case "XCBASIC.If_sa_stmt":
            stmt = new If_standalone_stmt(node, program);
        break;

        case "XCBASIC.Else_stmt":
            stmt = new Else_stmt(node, program);
        break;

        case "XCBASIC.Endif_stmt":
            stmt = new Endif_stmt(node, program);
        break;

        case "XCBASIC.Disableirq_stmt":
            stmt = new Disableirq_stmt(node, program);
        break;

        case "XCBASIC.Enableirq_stmt":
            stmt = new Enableirq_stmt(node, program);
        break;

        case "XCBASIC.Return_fn_stmt":
            stmt = new Return_fn_stmt(node, program);
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

abstract class Memmove_stmt: Stmt
{
    mixin StmtConstructor;

    abstract protected string getName();
    abstract protected string getMenmonic();

    void process()
    {
        auto args = this.node.children[0].children;

        Expression e;

        for(int i=2; i>=0; i--) {
            e = new Expression(args[i], this.program);
            e.eval();
            if(e.type == 'f') {
                this.program.error("Argument #" ~to!string(i+1)~ " of " ~this.getName()~ " must not be a float");
            }
            else if(e.type == 'b') {
                e.convert('w');
            }

            this.program.program_segment ~= to!string(e);
        }

        this.program.program_segment ~= "\t" ~this.getMenmonic()~ "\n";

        this.program.use_memlib = true;
    }
}
