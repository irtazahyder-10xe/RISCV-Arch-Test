/* CONSTANTS */
.equ MSTATUS_MPP1, 0x1000
.equ MSTATUS_MPP0, 0x800

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

  .p2align 4
  .global begin_signature
    begin_signature:
      .fill 2, 4, 0xdeadbeef
    end_signature:
  .size begin_signature, end_signature-begin_signature
.endm

.macro RVTEST_CODE_BEGIN
  .section .text.init
  .p2align  6
  .global _start
.endm

.macro PUSH_ALL from=1, to=31
  addi sp, sp, -4
  sw x\from, 0(sp)
  .if \from - \to
    PUSH_ALL "(\from + 1)", \to
  .endif
.endm

.macro POP_ALL from=1, to=31
  lw x\from, 0(sp)
  addi sp, sp, 4
  .if \from - \to
    POP_ALL "(\from + 1)", \to
  .endif
.endm
