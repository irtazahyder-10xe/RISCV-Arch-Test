.include "macro.S"

RVTEST_CODE_BEGIN
_start:
  /* Setting the stack pointer */
  la sp, _sstack
  call trap_init
  j main

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
  ret

  .p2align 2
  .type trap_vector, @function
trap_vector:
  csrr t5, mcause
  nop
  nop
  nop
  nop
  nop
  j write_tohost

