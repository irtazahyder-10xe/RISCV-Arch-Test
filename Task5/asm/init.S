.include "asm/macro.S"


RVTEST_CODE_BEGIN
_start:
  /* Setting the stack pointer */
  la sp, _sstack
  call vm_configure
  call trap_init
  j main

  /**
   * Virtual Memory configurations
   *
   * Initializes the satp register and sets the root page table entry
   * NOTE: This function is to be called before trap_init. CSRs will update
   * after trap_init is called.
   * ======================================================================
   * satp:
   *  [ MODE | ASID | PFN ]
   *      1     9     22
   *  - MODE: 1 (SV32)
   *  - ASID: 1
   *  - PFN : page_table address
   */
  .p2align 2
  .type vm_configure, @function
vm_configure:
  li t0, 0x201
  slli t0, t0, 22
  la t1, l0_pt
  srli t1, t1, 12
  or t0, t0, t1

  csrw satp, t0
  ret
  .size vm_configure, .-vm_configure


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
  j fetch_page_fault
  .p2align 2
  j load_page_fault
  .p2align 2
  j .trap_finish
  .p2align 2
  j store_page_fault
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish
  .p2align 2
  j .trap_finish

/**
 * TASK 3: Update trap handler and add routines for load/store/execute page faults
 *
 * These routines update the signature file, writing their respective mcause
 * values
 */
fetch_page_fault:
  li a0, 12
  ADD_TO_SIGNATURE a0
  j .trap_finish

load_page_fault:
  li a0, 13
  ADD_TO_SIGNATURE a0
  j .trap_finish

store_page_fault:
  li a0, 15
  ADD_TO_SIGNATURE a0
  j .trap_finish

/**
 * TASK 2: Update trap handler and add routines for load/store/execute access 
 * exceptions
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
