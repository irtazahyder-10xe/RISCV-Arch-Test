  .section .tor
  .global test_tor_instr
  .type test_tor_instr, @function
test_instrc:
  /* Writing 707 in register a0 and then returning */
  li a0, 0x707
  ret

  .section .napot
  .global test_napot_data
  .type test_napot_data, @object
test_data: .fill 4, 4, 0xdeadbeef
