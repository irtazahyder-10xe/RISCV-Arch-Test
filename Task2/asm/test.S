.include "asm/macro.S"

  .section .text
  .p2align 2
  .global main
  .type main, @function
main:
  /**
   * TBD
   */

  li a0, 0
  /* For initial tests without setting pmpxcfg L bits */
  call priv_change

  /* Initially as PMP is configured, access to main function in S and U mode are
   * disabled. As these sections are not explicitly defined, the below instruction
   * raises the illegal instruction access exception */
  add s0, zero, zero


  /* Testing X/W/R on defined regions from desired regions */
  /* ================== TOR ================== */
  /* Instruction access */
  la t0, _TOR_START
  jalr t0

  /* Write Access */
  la t0, _TOR_START
  sw t0, 4(t0)

  /* Read Access */
  lw t0, 4(t0)

  /* ================= NAPOT ================= */
  /* Instruction access */
  la t0, _NAPOT_START
  jalr t0

  /* Write Access */
  la t0, _NAPOT_START
  sw t0, 4(t0)

  /* Read Access */
  lw t0, 4(t0)

  /* Exiting test */
  j write_tohost

  .section .text
  .p2align 2
  .global write_tohost
  .type write_tohost, @function
write_tohost:
  li gp, 1
  sw gp, tohost, t5
  j write_tohost

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
  /* Saving value of return address into mepc */
  csrw mepc, ra
  li t0, MSTATUS_MPP1
  csrc mstatus, t0

  /* If a0 is 0, then setting MPP to 01(SUPERVISOR) */
  li t0, MSTATUS_MPP0
  csrs mstatus, t0
  beqz a0, .finish

  /* otherwise setting MPP to 00(USER) */
  csrc mstatus, t0

.finish:
  mret
  .size priv_change, .-priv_change

  /**
   * Keeps track of byte to write in signature.txt
   */
  .section .data
  .type signature_count, @object
  .global signature_count
  .p2align 2
signature_count:
  .word 0x00
  .size signature_count, 4

RVTEST_DATA_BEGIN
