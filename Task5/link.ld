OUTPUT_ARCH( "riscv" )
ENTRY(_start)
SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }
  .tohost ALIGN (0x1000) : { 
	  *(.tohost)
  }
  .text ALIGN (0x1000) : {
	  *(.text)
  }
  .data ALIGN (0x1000) : {
	  *(.data)
    *(.page_table)
  }
  .bss : {
	  *(.bss)
  }
  .scratch : ALIGN(0x1000) {
    _mscratch = .;
    . += 256;
    _sscratch = .;
    . += 256;
  }
  .stack : ALIGN(0x1000) {
	  _estack = .;
	  . += 128K;
	  _sstack = .;
  }
  _end = .;
}
