.include "asm/macro.S"


RVTEST_CODE_BEGIN
_start:
  /* Setting the stack pointer */
  la sp, _sstack
  call trap_init
  j main

  /**
   * Trap initializer
   *
   * Initializes the mstatus and mtvec registers
   */
  .p2align 2
  .type trap_init, @function
trap_init:
  /* Initialzing the processor in Mmode */
  li t0, MSTATUS_MPP0
  li t1, MSTATUS_MPP1
  or t0, t0, t1
  csrs mstatus, t0

  /* Setting value for mtvec */
  la t0, trap_vector
  /* Setting the last 2 bits to 0, which correspond to using direct method for csr */
  li t1, 0x3
  not t1, t1
  and t0, t0, t1
  csrw mtvec, t0

  /* Setting the mscratch CSR */
  la t0, _mscratch
  csrw mscratch, t0

  csrw mepc, ra
  mret

  .p2align 2
  .type trap_vector, @function
trap_vector:
  PUSH_ALL mscratch
  csrr s0, mcause

  la ra, mcause_jumptable
  slli s0, s0, 2
  add ra, ra, s0
  jr ra

.trap_finish:
  csrr ra, mepc
  addi ra, ra, 4
  csrw mepc, ra
  POP_ALL mscratch
  mret

  .p2align 2
mcause_jumptable:
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .umode_ecall_routine
  .p2align 2
  j .smode_ecall_routine
  .p2align 2
  j .trap_finish
  .p2align 2
  j .mmode_ecall_routine
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish

/**
 * TASK 1: Update trap handler and add routines for user and supervisor ecalls
 * so that they jump to 1 mode higher
 *
 * These routines update the value of register a0 to previous mode before trap
 * handler was invoked for ease in testing.
 */
.umode_ecall_routine:
  /* Updating MPP to supervisor mode: 00 -> 01 */
  li t0, MSTATUS_MPP0
  csrs mstatus, t0
  // Overwriting the location where a0 is saved
  li a0, 0x0
  sw a0, 40(sp)
  j .trap_finish

  .p2align 2
.smode_ecall_routine:
  /* Updating MPP to machine mode: 01 -> 11 */
  li t0, MSTATUS_MPP1
  csrs mstatus, t0
  // Overwriting the location where a0 is saved
  li a0, 0x1
  sw a0, 40(sp)
  j .trap_finish

.mmode_ecall_routine:
  li a0, 0x3
  sw a0, 40(sp)
  j .trap_finish
