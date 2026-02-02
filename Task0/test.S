#define RVTEST_DATA_BEGIN                                               \
        .pushsection .tohost,"aw",@progbits;                            \
        .align 6; .global tohost; tohost: .dword 0; .size tohost, 8;    \
        .align 6; .global fromhost; fromhost: .dword 0; .size fromhost, 8;\
        .popsection;                                                    \
        .align 4; .global begin_signature; begin_signature:
#define RVTEST_CODE_BEGIN                                               \
        .section .text.init;                                            \
        .align  6;                                                      \
        .global _start;                         \
_start:                                 \
        j main;                             \
trap_vector:                                                            \
    csrr t5, mcause ;                       \
    nop;                                \
    nop;                                \
    nop;                                \
    nop;                                \
    nop;                                \
    j write_tohost
RVTEST_CODE_BEGIN
main:
    la   x1, base
    lw   x4, 0(x1)
    csrr x2, mepc
    sw   x2, 0(x1)
    lw   x3, 0(x1)
    beq  x3, x4, test_fail
    j test_pass


test_fail:
	j test_fail

test_pass:
    j write_tohost
.align 2
write_tohost:
    li gp, 1
    sw gp, tohost, t5
    j write_tohost

.data
base:
.word 0xcafebeef
RVTEST_DATA_BEGIN
