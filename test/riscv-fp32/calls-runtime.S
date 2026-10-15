        .text
        .globl gcc_clobber
gcc_clobber:
        .irp reg,ft0,ft1,ft2,ft3,ft4,ft5,ft6,ft7,fa0,fa1,fa2,fa3,fa4,fa5,fa6,fa7,ft8,ft9,ft10,ft11
        fmv.w.x \reg,zero
        .endr
        li t0,0x40400000
        fmv.w.x fa0,t0
        ret

        .globl gcc_stack_alignment
gcc_stack_alignment:
        andi a0,sp,15
        ret

        .globl check_saved
check_saved:
        addi sp,sp,-64
#if __riscv_xlen == 64
        sd ra,56(sp)
#else
        sw ra,56(sp)
#endif
        .set saved_ofs,0
        .irp reg,fs0,fs1,fs2,fs3,fs4,fs5,fs6,fs7,fs8,fs9,fs10,fs11
        fsw \reg,saved_ofs(sp)
        .set saved_ofs,saved_ofs+4
        .endr
        .set saved_bits,0x3f800000
        .irp reg,fs0,fs1,fs2,fs3,fs4,fs5,fs6,fs7,fs8,fs9,fs10,fs11
        li t0,saved_bits
        fmv.w.x \reg,t0
        .set saved_bits,saved_bits+1
        .endr
        la a0,.Lsaved_arg
        call cc_overflow
        li a0,0
        .set saved_bits,0x3f800000
        .irp reg,fs0,fs1,fs2,fs3,fs4,fs5,fs6,fs7,fs8,fs9,fs10,fs11
        li t0,saved_bits
        fmv.x.w t1,\reg
        bne t0,t1,.Lsaved_bad
        .set saved_bits,saved_bits+1
        .endr
        j .Lsaved_restore
.Lsaved_bad:
        li a0,1
.Lsaved_restore:
        .set saved_ofs,0
        .irp reg,fs0,fs1,fs2,fs3,fs4,fs5,fs6,fs7,fs8,fs9,fs10,fs11
        flw \reg,saved_ofs(sp)
        .set saved_ofs,saved_ofs+4
        .endr
#if __riscv_xlen == 64
        ld ra,56(sp)
#else
        lw ra,56(sp)
#endif
        addi sp,sp,64
        ret

        .section .rodata
        .balign 4
.Lsaved_arg:
        .word 0x40400000
