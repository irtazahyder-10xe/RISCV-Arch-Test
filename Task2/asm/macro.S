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

  .equ XLEN, 8
  .equ WORDS, 2
  .p2align 4
  .global begin_signature
    begin_signature:
      .fill WORDS, XLEN/8, 0xAB
    end_signature:
  .size begin_signature, end_signature-begin_signature
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
