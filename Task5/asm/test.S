.include "asm/macro.S"

  .section .text
  .p2align 2
  .global main
  .type main, @function
main:
  /* Assigning VA to tohost section */
  /**
   * tohost VA: 0xcafe6000
   * VPN[1]: 'b1100_1010_11 = 0x32b
   * VPN[0]: 'b11_1110_0110 = 0x3e6
   */
  // li s0, DATA_VA
  // li t0, 0x1000
  // add s0, s0, t0

  li a0, 0x32b
  la a1, l0_pt
  srli a1, a1, 2
  li a2, 0x0
  li a3, 1
  call PTE_entry

  /* Making entry for VA where supervisor instructions are stored */
  la a0, 0x3e6
  la a1, tohost
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* Making entry for VA where supervisor instructions are stored */
  /**
   * smode_test VA: 0xcafe8000
   * VPN[1]: 'b1100_1010_11 = 0x32b
   * VPN[0]: 'b11_1110_1000 = 0x3e8
   */
  la a0, 0x32b
  la a1, l0_pt
  srli a1, a1, 2
  li a2, 0x0
  li a3, 1
  call PTE_entry

  /* Making entry for VA where supervisor instructions are stored */
  la a0, 0x3e8
  la a1, smode_test
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  sfence.vma

  // YOU DO NOT DO THIS SHIT IN M MODE, save physical address
  // /* Saving the virtual address of smode_test in mepc */
  // la s0, TEXT_VA
  // addi s0, s0, -4
  // csrw mepc, s0

  /* going to supervisor mode */
  li t0, MSTATUS_MPP1
  csrc mstatus, t0

  li t0, MSTATUS_MPP0
  csrs mstatus, t0

  /* Entering smode_test */
  li s0, 0
  lui s0, 0xcafe8
  csrw mepc, s0
  mret

  .section .test_text, "x"
  .global smode_test
  .p2align PAGE_SIZE_BITS
  .type smode_test, @function
smode_test:
  addi s0, s0, 5
  j test_pass
  .size smode_test, .-smode_test

  /**
   * Test passed
   */
  .p2align 2
  .global test_pass
  .type test_pass, @function
test_pass:
  li gp, 1
  sw gp, tohost, t5
  j test_pass

  /**
   * Test passed
   */
  .p2align 2
  .global test_fail
  .type test_fail, @function
test_fail:
  li gp, 3
  sw gp, tohost, t5
  j test_fail

  /**
   * @brief Add entry to PTE
   *
   * PTE format:
   * [ PPN[1] | PPN[2] | RSW (00) | D | A | G (0) | U | X | W | R | V ]
   * [   12   |   10   |     2    | 1 | 1 |  1    | 1 | 1 | 1 | 1 | 1 ]
   *
   * @params[in] a0[31:21] or a[20:10]: VPN[1] or VPN[0]
   * @params[in] a1: Physical Address [33:2]
   * @params[in] a2[2:0]: X/W/R permissions
   * @params[in] a3[0]: level
   */
  .section .text
  .p2align 2
  .global PTE_entry
  .type PTE_entry, @function
PTE_entry:
  /* Extracting PFN from PA */
  mv t0, a1
  li t1, 0xfffffc00
  and t0, t0, t1

  bnez a3, .l1_pte
  .l0_pte:
    /* Setting DA and V bits to 1 */
    ori t0, t0, 0xc1
    /* Setting the permission bits for X/W/R */
    slli t1, a2, 1
    or t0, t0, t1
    /* Loading l0 page tables address */
    la t1, l0_pt
    j .pte_save

  .l1_pte:
    /* Setting valid bit to 1 */
    ori t0, t0, 0x1
    /* Loading l1 page tables address */
    la t1, l1_pt

  .pte_save:
    slli t2, a0, 2
    add t1, t1, t2
    sw t0, 0(t1)
    ret
  .size PTE_entry, .-PTE_entry

  /**
   * Defining the root/l1 page table
   */
  .section .page_table
  .p2align PAGE_SIZE_BITS
  .global l1_pt
  .type l1_pt, @object
l1_pt:
  .zero PTB_BYTES
  .size l1_pt, .-l1_pt

  /**
   * Defining the leaf/l0 page table
   */
  .section .page_table
  .p2align PAGE_SIZE_BITS
  .global l0_pt
  .type l0_pt, @object
l0_pt:
  .zero PTB_BYTES
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
