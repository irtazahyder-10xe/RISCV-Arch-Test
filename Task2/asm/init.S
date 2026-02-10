.include "asm/macro.S"


RVTEST_CODE_BEGIN
_start:
  /* Setting the stack pointer */
  la sp, _sstack
  call pmp_configure
  call trap_init
  j main

  /**
   * PMP configurations
   *
   * Initializes the pmpicfg and corresponding pmpaddri csrs
   * NOTE: This function is to be called before trap_init. CSRs will update
   * after trap_init is called.
   */
  .p2align 2
  .type pmp_configure, @function
pmp_configure:
  /**
   *  pmpcfg0:
   *  [pmp3cfg 0 pmp1cfg pmp0cfg]
   *    - pmp0cfg: (0)00(0_1)(111)
   *      - L: 0, A: 01 (TOR), X/W/R: 111 (All permissions)
   *      - pmpaddr0: _end
   *      - For allowing data and code in test.S to run in umode and smode
   *        TOR on pmp0cfg automatically takes all region between pmpaddr0
   *        to start of the program.
   *
   *    - pmp1cfg: (0)00(1_1)(001)
   *      - L: 0, A: 11 (NAPOT), X/W/R: 001 (READ ONLY)
   *      - pmpaddr1: _NAPOT_START
   *
   *    - pmp3cfg: (0)00(0_1)(100)
   *      - L: 0, A: 01 (TOR), X/W/R: 100 (EXECUTE ONLY)
   *      - pmpaddr2: _TOR_START
   *      - pmpaddr3: _TOR_END
   */

  /* Initializing pmpcfg0 -> pmp3cfg | 0x00 | pmp1cfg | pmp0cfg */
  /* Configuring the asm in test.S to be able to run in U or S mode */
  /* Comment this line to review the exception generated in 5 */
  li t0, PMP_XMODE_MAIN_CONFIG

  li t1, PMP_NAPOT_CONFIG
  sll t1, t1, 8
  or t0, t0, t1

  li t3, PMP_TOR_CONFIG
  sll t3, t3, 24
  or t0, t0, t3

  csrw pmpcfg0, t0

  /* Initializing pmpaddrX csrs */
  la t0, _end
  srli t0, t0, 2
  csrw pmpaddr0, t0

  la t1, _NAPOT_START
  srli t1, t1, 2
  ori t1, t1, PMPADDR_NAPOT_4K_MASK
  csrw pmpaddr1, t1

  la t2, _TOR_START
  srli t2, t2, 2
  csrw pmpaddr2, t2

  la t3, _TOR_END
  srli t3, t3, 2
  csrw pmpaddr3, t3
  ret
  .size pmp_configure, .-pmp_configure


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
  .size trap_init, .-trap_init

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
  j exec_access_routine
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j load_access_routine
  .p2align 2
  j .trap_finish
  .p2align 2
  j store_access_routine
  .p2align 2
  j umode_ecall_routine
  .p2align 2
  j smode_ecall_routine
  .p2align 2
  j .trap_finish
  .p2align 2
  j mmode_ecall_routine
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
 * TASK 2: Update trap handler and add routines for load/store/execute exceptions
 *
 * These routines update the signature file, writing their respective mcause
 * values
 */
exec_access_routine:
  li a0, 0x1
  ADD_TO_SIGNATURE a0

  // As we are testing the execution functionality by jumping to the address,
  // mepc should hold value of ra - 4
  csrrw t0, mscratch, t0
  lw ra, 4(t0)
  addi ra, ra, -4
  csrw mepc, ra
  csrrw t0, mscratch, t0
  j .trap_finish

load_access_routine:
  li a0, 0x5
  ADD_TO_SIGNATURE a0
  j .trap_finish

store_access_routine:
  li a0, 0x7
  ADD_TO_SIGNATURE a0
  j .trap_finish

/**
 * TASK 1: Update trap handler and add routines for user and supervisor ecalls
 * so that they jump to 1 mode higher
 *
 * These routines update the value of register a0 to previous mode before trap
 * handler was invoked for ease in testing.
 */
umode_ecall_routine:
  /* Updating MPP to supervisor mode: 00 -> 01 */
  li t0, MSTATUS_MPP0
  csrs mstatus, t0
  // li a0, 0x0
  // ADD_TO_SIGNATURE a0
  j .trap_finish

smode_ecall_routine:
  /* Updating MPP to machine mode: 01 -> 11 */
  li t0, MSTATUS_MPP1
  csrs mstatus, t0
  // li a0, 0x1
  // ADD_TO_SIGNATURE a0
  j .trap_finish

mmode_ecall_routine:
  // li a0, 0x3
  // ADD_TO_SIGNATURE a0
  j .trap_finish
