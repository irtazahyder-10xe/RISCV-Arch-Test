.include "macro.S"

  .section .text
  .p2align 2
  .global main
  .type main, @function
main:
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

  /**
   * Changes privilege level to User or Supervisor
   * NOTE: This function should only be called from machine mode
   * @param[in]: a0 is 0, change priv_mode to supervisor
   *           : a0 is 1, change priv_mode to user
   */
  .section .text
  .p2align 2
  .global write_tohost
  .type priv_change, @function
priv_change:
  // Saving value of return address into mepc
  csrw mepc, ra
  li t0, MSTATUS_MPP1
  csrc mstatus, t0

  // If a0 is 0, then setting MPP to 01(SUPERVISOR)
  li t0, MSTATUS_MPP0
  csrs mstatus, t0
  beqz a0, .finish

  // otherwise setting MPP to 00(USER)
  csrc mstatus, t0

.finish:
  mret
  .size priv_change, .-priv_change
RVTEST_DATA_BEGIN
