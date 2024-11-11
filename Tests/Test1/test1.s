    .section .text
    .globl _start

_start:
    li t0, 100
    li t1, 2
    sw t1, 0(t0)

    li t0, 104
    li t1, 5
    sw t1, 0(t0)

    li t0, 100
    lw t1, 0(t0)

    li t0, 104
    lw t2, 0(t0)

    add t3, t1, t2

    li t0, 108
    sw t3, 0(t0)

    j _start
