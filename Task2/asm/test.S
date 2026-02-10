.include "asm/macro.S"

  .section .text
  .p2align 2
  .global main
  .type main, @function
main:
  li a0, 0
  /* For initial tests without setting pmpxcfg L bits */
  call priv_change

  /* Initially as PMP is configured, access to main function in S and U mode are
   * disabled. As these sections are not explicitly defined, the below instruction
   * raises the illegal instruction access exception.
   * Will write 1 to signature file
   */
  add s0, zero, zero

  call memory_test

  /* As we are in supervisor mode, using the supervisor ECALL we should
   * enter machine mode, similar to what we did in Task 1. */
  ecall

  /* Setting up the MPRV bit and pmpconfig lock */
  /* For applying PMP on M-mode accesses */
  li t2, MSTATUS_MPRV
  csrs mstatus, t2

  csrr t0, pmpcfg0
  li t1, PMP_LOCK_MASK
  or t0, t0, t1
  csrw pmpcfg0, t0

  la ra, .test_MPRV
  csrw mepc, ra
  mret

.test_MPRV:
  call memory_test

  /* Exiting test */
  j write_tohost

  /**
   * PMP TOR and NATOP tests
   */
  .section .text
  .p2align 2
  .global memory_test
  .type memory_test, @function
memory_test:
  /* Testing X/W/R on defined regions from desired regions */
  /* ================== TOR ================== */
  /* Instruction access */
  addi sp, sp, -4
  sw ra, 0(sp)

  la t0, _TOR_START
  jalr t0

  /* Write Access, should write 7 to signature file */
  la t0, _TOR_START
  sw t0, 4(t0)

  /* Read Access, should write 5 to signature file */
  la t0, _TOR_START
  lw t0, 4(t0)

  /* ================= NAPOT ================= */
  /* Instruction access, should write 1 to signature file */
  la t0, _NAPOT_START
  jalr t0

  /* Write Access, should write 7 to signature file */
  la t0, _NAPOT_START
  sw t0, 4(t0)

  /* Read Access */
  la t0, _NAPOT_START
  lw t0, 4(t0)
  lw ra, 0(sp)
  addi sp, sp, 4
  ret
  .size memory_test, .-memory_test

  /**
   * Changes privilege level to User or Supervisor
   * NOTE: This function should only be called from machine mode
   * @param[in]: a0 is 0, change priv_mode to supervisor
   *           : a0 is 1, change priv_mode to user.
   */
  .section .text
  .p2align 2
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
   * Write to host
   */
  .section .text
  .p2align 2
  .global write_tohost
  .type write_tohost, @function
write_tohost:
  li gp, 1
  sw gp, tohost, t5
  j write_tohost

  /**
   * Keeps track of byte to write in signature.txt
   */
  .section .data
  .type signature_offset, @object
  .global signature_offset
  .p2align 2
signature_offset:
  .word 0x00
  .size signature_offset, 4

RVTEST_DATA_BEGIN
