.include "asm/macro.S"

  .section .text
  .p2align 2
  .global main
  .type main, @function
main:
  .p2align 6
  /* Verifying we are in machine mode */
  /* 1st word written in signature.txt should be 3 */
  ecall

  /* Downgrading to user mode */
  call to_usermode

  /* Executing illegal instruction. The illegal instruction choosen is reading
   * from sstatus register. This operation ONLY invokes trap handler if we are
   * in user mode.
   *
   * The smode trap handler should be invoked and the 2nd word written in 
   * signature.txt should be 1
   */
  csrr t0, sstatus

  j write_tohost

  /**
   * Changes privilege level to User
   *
   * NOTE: This function should only be called from machine mode
   */
  .section .text
  .p2align 2
  .global to_usermode
  .type to_usermode, @function
to_usermode:
  /* Saving value of return address into mepc */
  csrw mepc, ra

  /* Changing MPP to 00 to downgrade to user mode after mret */
  li t1, MSTATUS_MPP1
  li t0, MSTATUS_MPP0
  or t1, t1, t0
  csrc mstatus, t1
  mret

  .section .text
  .p2align 2
  .global write_tohost
  .type write_tohost, @function
write_tohost:
  li gp, 1
  sw gp, tohost, t5
  j write_tohost

  .section .data
  .p2align 2
  .global signature_word
  .type signature_word, @object
signature_word: .word 0
  .size signature_word, 4

RVTEST_DATA_BEGIN
