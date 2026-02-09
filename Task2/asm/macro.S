/* CONSTANTS */
.equ MSTATUS_MPP1, 1 << 12
.equ MSTATUS_MPP0, 1 << 11
.equ MSTATUS_MPRV, 1 << 17

.equ PMP_XMODE_MAIN_CONFIG, 0x0F

.equ PMP_TOR_CONFIG, 0x0C

.equ PMP_NAPOT_CONFIG, 0x19
.equ PMPADDR_NAPOT_4K_MASK, 0x1FF

.equ PMP_LOCK_MASK, 0x80808080

.equ PMPADDR_4K_NAPOT, 0x1FF

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
  .equ SPACE, 8
  .p2align 4
  .global begin_signature
    begin_signature:
      .fill SPACE, XLEN/8, 0x00
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

.macro ADD_TO_SIGNATURE reg
  la t0, begin_signature
  lw t1, signature_offset
  add t0, t0, t1
  sb \reg, 0(t0)
  addi t1, t1, 1

  la t0, signature_offset
  sw t1, 0(t0)
.endm
