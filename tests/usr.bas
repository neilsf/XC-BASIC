    rem -- example implementation of the << (left shift)
    rem -- operation using an USR function

    print usr(@fn_leftShift, 896)
    end

    rem -- Function fn_leftShift(int argument)
    rem --

    fn_leftShift:
    asm "
      ; The argument is available on the stack
      tsx
      asl $0102,x
      rol $0101,x

      ; The callee will pull back the result from the stack

      ; Note this is the only valid way to return from an user function
      jmp ($02fe)
    "
