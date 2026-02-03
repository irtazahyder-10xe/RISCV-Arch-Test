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
