/* CONSTANTS */
.equ MSTATUS_MPP1, 0x1000
.equ MSTATUS_MPP0, 0x800

.equ PTE_COUNT_BITS, 10
.equ PTB_BYTES, (1 << PTE_COUNT_BITS) * 4
.equ PAGE_SIZE_BITS, 12

.equ VPN1_mask, 0xFFC00000
.equ VPN0_mask, 0x003FF000

.equ DATA_VA, 0xdead4000
.equ TEXT_VA, 0xcafe8000
.altmacro

.macro RVTEST_DATA_BEGIN
  .pushsection .tohost,"aw",@progbits
    .p2align 6
    .global tohost
    tohost: .dword 0
    .size tohost, .-tohost

    .p2align 6
    .global fromhost
    fromhost: .dword 0
    .size fromhost, .-fromhost

    .equ XLEN, 8
    .equ COUNT, 10
    .p2align 4
    .global begin_signature
  begin_signature:
    .fill COUNT, XLEN/8, 0x00
  end_signature:
  .size begin_signature, end_signature-begin_signature

    .type signature_offset, @object
    .global signature_offset
    .p2align 2
  signature_offset:
    .word 0x00
    .size signature_offset, 4
  .popsection
.endm

.macro RVTEST_CODE_BEGIN
  .section .text.init
  .p2align  6
  .global _start
.endm

.macro PUSH from=1, to=31
  sw x\from, 4*\from(t0)
  .if \to - \from
    PUSH %(\from+1), \to
  .endif
.endm

.macro PUSH_ALL scratch
  csrrw t0, scratch, t0
  PUSH 1, 31
  csrrw t0, scratch, t0
.endm

.macro POP from=1, to=31
  lw x\from, 4*\from(t0)
  .if \to - \from
    POP %(\from+1), \to
  .endif
.endm

.macro POP_ALL scratch
  csrrw t0, scratch, t0
  POP 1, 31
  csrrw t0, scratch, t0
.endm

.macro ADD_TO_SIGNATURE reg
  la t0, begin_signature
  lw t1, signature_offset
  add t0, t0, t1
  sb \reg, 0(t0)
  addi t1, t1, 1

  la t0, signature_offset
  sw t1, 0(t0)
.endm

