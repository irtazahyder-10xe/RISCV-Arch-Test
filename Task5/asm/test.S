.include "asm/macro.S"

  .section .text
  .p2align PTSIZE
  .global main
  .type main, @function
main:
  /* Setting up translation for main label in .text section */
  la a0, main
  la a1, l1_pt
  srli a1, a1, 2
  li a2, 0x0
  li a3, 1
  call PTE_entry

  la a0, main
  la a1, main
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* Setting up PTE entry for .data section */
  li a0, VA
  la a1, l1_pt
  // As argument a1 is [33:2] instead of [31:0]
  srli a1, a1, 2
  li a2, 0x0
  li a3, 1
  call PTE_entry

  li a0, VA
  la a1, .data
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* going to user mode */
  li a0, 1
  call priv_downgrade
  addi s0, s0, 5
  j write_tohost

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
  /* Shifting by only 10 bits because last 2 bits of 34 bit PA ignored */
  li t0, 0
  srli a1, a1, 10

.set_pte:
  li s1, 1
  slli a2, a2, 1
  /* Setting the valid and permission bits */
  or s1, s1, a2

  /* Setting the PFN entry in PTE */
  slli a1, a1, 10
  or s1, s1, a1

.save_pte:

  /* Computing Page Table index */
  la s0, l0_pt
  /* Extracting first 10 bits from VA */
  li t0, VPN1_mask
  and t0, t0, a0
  /* VPN[1] * 4, as memory word aligned, so left shift by 22 - 2 = 20 */
  srli t0, t0, 20

  /* Adding the bits to the address */
  add s0, s0, t0
  beqz a3, .l1_pte

.l0_pte:
  /* This is a level 1 entry, so it is pointer to another page table */
  /* As pointer to page table, X/W/R = 000 */
  andi s1, s1, XWR_zero_mask
  j .pte_entry_finish

.l1_pte:
  /* As this is leaf pte, need to first find the L0 page */
  /* Then add the VPN0 offset into the address to it */
  lw s0, 0(s0)
  andi s0, s0, ~0x3FF
  slli s0, s0, 2
  li t0, VPN0_mask
  and t0, t0, a0
  /* VPN[0] * 4, as memory word aligned, so left shift by 12 - 2 = 10 */
  srli t0, t0, 10
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
   * @param[in]: a0 is 1, change priv_mode to supervisor
   *           : a0 is 0, change priv_mode to user
   */
  .section .text
  .p2align 2
  .global write_tohost
  .type priv_change, @function
priv_downgrade:
  /* Saving value of return address into mepc */
  csrw mepc, ra
  li t0, MSTATUS_MPP1
  csrc mstatus, t0

  /* If a0 is 0, then setting MPP to 01(SUPERVISOR) */
  li t0, MSTATUS_MPP0
  csrs mstatus, t0
  bnez a0, .finish

  /* otherwise setting MPP to 00(USER) */
  csrc mstatus, t0
.finish:
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
   * Defining the root/L0 page table
   */
  .section .page_table
  .p2align PTSIZE
  .global l0_pt
  .type l0_pt, @object
l0_pt:
  .fill PTEs, 4, 0x00000000
  .size l0_pt, .-l0_pt

  /**
   * Defining the L1 page table
   */
  .section .page_table
  .p2align PTSIZE
  .global l1_pt
  .type l1_pt, @object
l1_pt:
  .fill PTEs, 4, 0x00000000
  .size l1_pt, .-l1_pt

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
