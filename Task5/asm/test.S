.include "asm/macro.S"

  .section .text
  .p2align 2
  .global main
  .type main, @function
main:
  /* Making entry for VA where supervisor instructions are stored */
  li a0, TEXT_VA
  la a1, l0_pt
  srli a1, a1, 2
  li a2, 0x0
  li a3, 1
  call PTE_entry

  /* Making entry for VA where supervisor instructions are stored */
  li a0, TEXT_VA
  la a1, smode_exec_test
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* Saving the virtual address of smode_exec_test in mepc */
  la s0, TEXT_VA
  addi s0, s0, -4
  csrw mepc, s0

  /* going to user mode, after this we automatically jump to smode_exec_test */
  li a0, 1
  call priv_downgrade

  .section .test_text, "x"
  .global smode_exec_test
  .p2align PAGE_SIZE
  .type smode_exec_test, @function
smode_exec_test:
  addi s0, s0, 5
  j write_tohost
  .size smode_exec_test, .-smode_exec_test

  /**
   * @brief Add entry to PTE
   *
   * PTE format:
   * [ PPN[1] | PPN[2] | RSW (00) | D | A | G (0) | X | W | R | V ]
   * [   12   |   10   |     2    | 1 | 1 |  1    | 1 | 1 | 1 | 1 ]
   *
   * @params[in] a0: Virtual Address
   * @params[in] a1: Physical Address [33:2]
   * @params[in] a2[2:0]: X/W/R permissions
   * @params[in] a3[0]: level
   */
  .section .text
  .p2align 2
  .global PTE_entry
  .type PTE_entry, @function
PTE_entry:
  addi sp, sp, -16
  sw ra, 12(sp)
  sw s1, 8(sp)
  sw s0, 4(sp)
  /* Initializing the PTE entry */
  /* s1 = PTE value */
  /* s0 = Page table address to save value */
  /* PFN = PA >> 10 (as the register a1 already ignores the last 2 bits) */
  srli a1, a1, 10

.set_pte:
  slli a2, a2, 1
  /* Setting the valid and permission bits */
  addi s1, a2, 1

  /* Setting the pte.PFN */
  slli a1, a1, 10
  or s1, s1, a1

.save_pte:
  /* Computing Page Table index */
  la s0, l1_pt
  /* Extracting first 10 bits from VA */
  li t0, VPN1_mask
  and t0, t0, a0

  /* VPN[1] x 4, the mask ensures all other bits are zero */
  srli t0, t0, 20

  /* Adding the bits to the address */
  add s0, s0, t0
  beqz a3, .l0_pte

.l1_pte:
  /* This is a level 1 entry, so it is pointer to another page table */
  /* As pointer to page table, X/W/R = 000 */
  andi s1, s1, XWR_zero_mask
  j .pte_entry_finish

.l0_pte:
  /* As this is leaf pte, need to first find the L1 PTE */
  /* Extracting virtual page address from L1 page table */
  lw s0, 0(s0)
  andi s0, s0, ~0x3FF
  slli s0, s0, 2

  /* Extracing VPN0 bits from VA */
  li t0, VPN0_mask
  and t0, t0, a0
  srli t0, t0, 12

  /* VPN[0] * 4, as memory word aligned */
  slli t0, t0, 2

  /* Then add the VPN0 offset into the address to it */
  add s0, s0, t0

.pte_entry_finish:
  sw s1, 0(s0)

  lw s0, 4(sp)
  lw s1, 8(sp)
  lw ra, 12(sp)
  addi sp, sp, 16

  ret
  .size PTE_entry, .-PTE_entry

  /**
   * Changes privilege level to User or Supervisor
   * NOTE: This function should only be called from machine mode
   * NOTE: It is the callee's responsibility to set mepc appropriately before
   *       calling this function
   * @param[in]: a0 is 1, change priv_mode to supervisor
   *           : a0 is 0, change priv_mode to user
   */
  .section .text
  .p2align 2
  .global write_tohost
  .type priv_change, @function
priv_downgrade:
  /* If a0 is 0, then setting MPP to 00(USER) */
  li t0, MSTATUS_MPP0
  csrc mstatus, t0

  li t1, MSTATUS_MPP1
  csrc mstatus, t1
  beqz a0, .finish

  /* otherwise setting MPP to 01(SUPERIVISOR) */
  csrs mstatus, t0
.finish:
  csrr ra, mepc
  addi ra, ra, 4
  csrw mepc, ra

  mret
  .size priv_downgrade, .-priv_downgrade

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
   * Defining the root/l1 page table
   */
  .section .page_table
  .p2align PAGE_SIZE
  .global l1_pt
  .type l1_pt, @object
l1_pt:
  .fill PTEs, 4, 0x00000000
  .size l1_pt, .-l1_pt

  /**
   * Defining the leaf/l0 page table
   */
  .section .page_table
  .p2align PAGE_SIZE
  .global l0_pt
  .type l0_pt, @object
l0_pt:
  .fill PTEs, 4, 0x00000000
  .size l0_pt, .-l0_pt

  /**
   * Random data to be accessed to show virtual memory is working
   */
  .section .data
  .p2align 2
  .global test_data
  .type test_data, @object
test_data:
  .fill 10, 4, 0xbeefcafe
  .size test_data, .-test_data

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
