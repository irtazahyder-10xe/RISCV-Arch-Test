.include "asm/macro.S"

  .section .text
  .p2align 2
  .global main
  .type main, @function
main:
  /**
   * VPN[1]: 'b1100_1010_11 = 0x32b
   * VPN[0]: 'b11_1110_xxxx = 0x3e{x} where x are same as PFN[0]
   */

  li a0, 0x32b
  la a1, l0_pt
  srli a1, a1, 2
  li a2, 0x0
  li a3, 1
  call PTE_entry

  /* .tohost */
  la a0, 0x3e1
  la a1, tohost
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* main */
  la a0, 0x3e2
  la a1, PTE_entry
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* l1_pt */
  la a0, 0x3e4
  la a1, l1_pt
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* l0_pt */
  la a0, 0x3e5
  la a1, l0_pt
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* Making entry for VA where supervisor instructions are stored */
  /**
   * smode_test VA: 0xcafe3000
   * VPN[1]: 'b1100_1010_11 = 0x32b
   * VPN[0]: 'b11_1110_0011 = 0x3e3
   */
  la a0, 0x3e3
  la a1, smode_test
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry

  /* Making entry for VA page test_data, initially is has X/W/R permissions */
  /**
   * test_data VA: 0xdead4000
   * VPN[1]: 0x37a
   * VPN[0]: 0x2d4
   */
  la a0, 0x37a
  la a1, l0_pt
  srli a1, a1, 2
  li a2, 0x0
  li a3, 1
  call PTE_entry

  la a0, 0x2d4
  la a1, test_data
  srli a1, a1, 2
  li a2, 0x7
  li a3, 0
  call PTE_entry
  sfence.vma

  /* going to supervisor mode */
  li t0, MSTATUS_MPP1
  csrc mstatus, t0

  li t0, MSTATUS_MPP0
  csrs mstatus, t0

  /* Entering smode_test */
  li s0, 0
  lui s0, 0xcafe3
  csrw mepc, s0
  mret

  .section .test_text, "x"
  .global smode_test
  .p2align PAGE_SIZE_BITS
  .type smode_test, @function
smode_test:
  /* test_data VA: 0xdead4000 */
  la s0, 0xdead4000

  /**
   * Page test where the page has all X/W/R privileges
   *
   * Pass condition:
   *    - Singature_offest == 0
   */
.smode_xwr_page:

  /* Execute test */
  jalr ra, s0, 40

  /* Write test */
  li t0, 0xcafebeef
  sw t0, 8(s0)

  /* Read test */
  lw t0, 8(s0)
  li t1, 0xcafebeef
  bne t1, t0, test_fail

  /* Test failed if any above instructions wrote mcause in signature file */
  li s1, 0xcafe105c
  lw s1, 0(s1)
  bnez s1, test_fail

  /**
   * Page test where the page has all RW but no X privileges
   *
   * Pass condition:
   *    - Singature_offest == 1
   *    - begin_signature[0] byte == 12
   */
.smode_wr_page:
  /* In s mode we need to give physical address explicitly */
  la a0, 0x2d4
  lui a1, 0x80006
  srli a1, a1, 2
  li a2, 0x3 /* read & write permission */
  li a3, 0
  call PTE_entry

  li t0, 0xcafe5000
  sfence.vma t0, zero

  /* Execute test */
  jalr ra, s0, 40

  /* Write test */
  li t0, 0xcafebeef
  sw t0, 8(s0)

  /* Read test */
  lw t0, 8(s0)
  li t1, 0xcafebeef
  bne t1, t0, test_fail

  /* Test passes if ONLY if the fetch instruction fails */
  li s1, 0xcafe105c
  lw s1, 0(s1)
  li t0, 1
  bne s1, t0, test_fail

  li t1, 0xcafe1050
  add t1, t1, s1
  lbu t1, -1(t1)

  li t0, 12
  bne t1, t0, test_fail

  /**
   * Page test where the page has all only read permission
   */
.smode_r_page:
  la a0, 0x2d4
  lui a1, 0x80006
  srli a1, a1, 2
  li a2, 0x1 /* read only permission */
  li a3, 0
  call PTE_entry

  li t0, 0xcafe5000
  sfence.vma t0, zero

  /* Execute test */
  jalr ra, s0, 40

  /* Write test */
  li t0, 0xcafebeef
  sw t0, 8(s0)

  /* Read test */
  lw t0, 8(s0)
  li t1, 0xcafebeef

   /**
   * Pass condition:
   *    - Singature_offest == 3
   *    - begin_signature[2] byte == 15
   *    - begin_signature[1] byte == 12
   */
  li s1, 0xcafe105c
  lw s1, 0(s1)
  li t0, 3
  bne s1, t0, test_fail

  li t1, 0xcafe1050
  add t1, t1, s1
  lbu t2, -1(t1)
  li t0, 15
  bne t2, t0, test_fail

  lbu t2, -2(t1)
  li t0, 12
  bne t2, t0, test_fail

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
   * Test failed
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
   * NOTE: This function should only be called in machine mode
   *       as it uses l1_pt and l2_pt's physical addresses
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
  .section .test_data
  .p2align 2
  .global test_data
  .type test_data, @object
test_data:
  // test data for read and write
  .fill 10, 4, 0xbeefcafe

  // test instructions at offset of 10 words
  nop
  nop
  ret
  .size test_data, .-test_data
RVTEST_DATA_BEGIN
