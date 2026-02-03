.include "macro.S"

_start:
        j main

trap_vector:
    csrr t5, mcause
    nop
    nop
    nop
    nop
    nop
    j write_tohost

RVTEST_CODE_BEGIN
main:
    .p2align 6
    nop
    nop
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
