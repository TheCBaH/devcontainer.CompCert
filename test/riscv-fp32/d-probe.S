        .text
        .globl _start
_start:
        fadd.d ft0, ft0, ft0
        li a0, 0
        li a7, 93
        ecall
