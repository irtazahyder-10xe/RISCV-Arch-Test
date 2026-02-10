  .section .tor, "x"
  .global test_tor_instr
  .type test_tor_instr, @function
test_tor_instrc:
  /* returns to the caller */
  ret

  .section .napot, "w", @progbits
  .global test_napot_data
  .type test_napot_data, @object
test_napot_data: .fill 4, 4, 0xdeadbeef
