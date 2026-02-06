/* CONSTANTS */
.equ MSTATUS_MPP1, 0x1000
.equ MSTATUS_MPP0, 0x800

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
  .popsection

  .equ XLEN, 32
  .equ WORDS, 4
  .p2align 4
  .global begin_signature
    begin_signature:
      .fill WORDS*(XLEN/32), 4, 0x00000000
    end_signature:
  .size begin_signature, end_signature-begin_signature
.endm

.macro RVTEST_CODE_BEGIN
  .section .text.init
  .p2align  6
  .global _start
.endm

.macro PUSH from=1, to=31
  sw x\from, 4*\from(sp)
  .if \from - \to
    PUSH %(\from+1), \to
  .endif
.endm

.macro PUSH_ALL
  addi sp, sp, -32*4
  PUSH 1, 31
.endm

.macro POP from=1, to=31
  lw x\from, 4*\from(sp)
  .if \from - \to
    POP %(\from+1), \to
  .endif
.endm

.macro POP_ALL
  POP 1, 31
  addi sp, sp, 32*4
.endm
