OUTPUT_ARCH( "riscv" )
ENTRY(_start)
SECTIONS
{
  . = 0x80000000;
  .text.init : { *(.text.init) }
  .tohost ALIGN (4K) : { 
	  *(.tohost)
  }
  .text ALIGN (4K) : {
	  *(.text)
  }
  .data ALIGN (4K) : {
	  *(.data)
  }
  .bss : {
	  *(.bss)
  }
  .scratch : ALIGN(4K) {
    _mscratch = .;
    . += 256;
    /* _sscratch = .;
    . += 256; */
  }
  .stack : ALIGN(4K) {
	  _estack = .;
	  . += 128K;
	  _sstack = .;
  }
  _end = .;
  .pmp ALIGN(4K) : {
    _TOR_START = .;
    *(.tor)
    _TOR_END = ALIGN(4K);

    _NAPOT_START = ALIGN(4K);
    *(.napot)
    . = ALIGN(4K);
  }
}
