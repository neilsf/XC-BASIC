module library.nucleus;

string get_code(string platform)
{
    string code;
    switch(platform) {
        case "c16":
            code = import("c16/psregs.asm") ~ "\n" ~ import("c16/fpaddr.asm");
            break;

        case "c64":
            code = import("c64/psregs.asm") ~ "\n" ~ import("c64/fpaddr.asm");
            break;

        case "cplus4":
            code = import("cplus4/psregs.asm") ~ "\n" ~ import("cplus4/fpaddr.asm");
            break;

        case "vic20":
            code = import("vic20/psregs.asm") ~ "\n" ~ import("vic20/fpaddr.asm");
            break;

        case "c128":
            code = import("c128/psregs.asm") ~ "\n" ~ import("c128/fpaddr.asm");
            break;

        default:
            assert(0);
    }

    code ~= "\n" ~ import("nucleus.asm");
    return code;
}


