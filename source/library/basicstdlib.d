module library.basicstdlib;

string get_code(string platform)
{
    string code;
    switch(platform) {
        case "c16":
            code = import("c16/stdlib.asm");
            break;

        case "c64":
            code = import("c64/stdlib.asm");
            break;

        case "cplus4":
            code = import("cplus4/stdlib.asm");
            break;

        case "vic20":
            code = import("vic20/stdlib.asm");
            break;

        case "c128":
            code = import("c128/stdlib.asm");
            break;

        default:
            assert(0);
    }

    return code;
}
