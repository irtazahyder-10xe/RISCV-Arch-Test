.include "macro.S"

  .section .text
  .p2align 2
  .global main
  .type main, @function
main:
  .p2align 6
  // Testing whether we are in machine mode or not
  csrr t5, mcycle
  j write_tohost

  .section .text
  .p2align 2
  .global write_tohost
  .type write_tohost, @function
write_tohost:
  li gp, 1
  sw gp, tohost, t5
  j write_tohost

  .data
base:
  .word 0xcafebeef

RVTEST_DATA_BEGIN
