        .text
        .globl fp64_report
fp64_report:
        mv a2,a1
        mv a1,a0
        li a0,1
        li a7,64
        ecall
        ret
