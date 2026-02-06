.include "asm/macro.S"

RVTEST_CODE_BEGIN
_start:
  /* Setting the stack pointer */
  la sp, _sstack
  call trap_init
  j main

  .p2align 2
  .type trap_init, @function
trap_init:
  /* ========== MACHINE MODE ========== */
  /* Initialzing the processor in Mmode */
  li t1, MSTATUS_MPP1
  li t0, MSTATUS_MPP0
  or t0, t0, t1
  csrs mstatus, t0

  /* Setting value for mtvec */
  /* Setting the last 2 bits to 0, which correspond to using direct method for csr */
  la t0, mmode_trap_vector
  li t1, 0x3
  not t1, t1
  and t0, t0, t1
  csrw mtvec, t0

  /* Setting up the scratch register */
  la t0, _mscratch
  csrw mscratch, t0

  /* ========== SUPERVISOR MODE ========== */
  /**
   * Setting 3rd bit of medeleg to ensure user or supervisor mode illegal
   * instruction is dealt by the smode trap handler
   */
  csrsi medeleg, 0x4

  /* Setting value for stvec */
  /* Setting the last 2 bits to 0, which correspond to using direct method for csr */
  la t0, smode_trap_vector
  li t1, 0x3
  not t1, t1
  and t0, t0, t1
  csrw stvec, t0

  /* Setting up the scratch register */
  la t0, _sscratch
  csrw sscratch, t0

  csrw mepc, ra
  mret

  /**
   * M-mode trap handler
   *
   * Whenever the mmode trap handler is accessed, 11 is written into the
   * signature file.
   */
  .p2align 2
  .type mmode_trap_vector, @function
mmode_trap_vector:
  PUSH_ALL mscratch

  /* Updating the signature word to point to next word in signature file */
  la t1, signature_word
  lw t2, 0(t1)
  addi t3, t2, 1
  sw t3, 0(t1)

  /* Writing 03 in signature file to show machine trap handler invoked */
  la t0, begin_signature
  add t3, t2, t0
  li t4, 0x3
  sb t4, 0(t3)

  csrr s0, mcause
  slli s0, s0, 2
  la s1, mmode_jumptable
  add s1, s1, s0
  jr s1

.mmode_trap_finish:
  csrr t0, mepc
  addi t0, t0, 4
  csrw mepc, t0

  POP_ALL mscratch
  mret

  /**
   * S-mode trap handler
   *
   * Whenever the smode trap handler is accessed, 01 is written into the
   * signature file.
   */
  .p2align 2
  .type smode_trap_vector, @function
smode_trap_vector:
  PUSH_ALL sscratch

  /* Updating the signature word to point to next word in signature file */
  la t1, signature_word
  lw t2, 0(t1)
  addi t3, t2, 1
  sw t3, 0(t1)

  /* Writing 01 in signature file to show supervisor trap handler invoked */
  la t0, begin_signature
  add t3, t2, t0
  li t4, 0x1
  sb t4, 0(t3)

  csrr s0, scause
  slli s0, s0, 2
  la s1, smode_jumptable
  add s1, s1, s0
  jr s1

.smode_trap_finish:
  csrr t0, sepc
  addi t0, t0, 4
  csrw sepc, t0

  POP_ALL sscratch
  sret


  /**
   * Jump table accessed by M-mode trap handler
   */
   .type mmode_jumptable, @function
mmode_jumptable:
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish
  .p2align 2
  j .mmode_trap_finish

  /**
   * Jump table accessed by S-mode trap handler
   */
   .type smode_jumptable, @function
smode_jumptable:
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
  .p2align 2
  j .smode_trap_finish
