OUTPUT_ARCH(aarch64)
ENTRY(_start)

 STACK_SIZE = DEFINED(STACK_SIZE) ? STACK_SIZE : 0x1000;
 HEAP_SIZE = DEFINED(HEAP_SIZE) ? HEAP_SIZE : (0x3000000 - _end);
SECTIONS
{
	/*
	 * First and formost we need the .init section, then all the rest of the code. 
	 */
	.text 0x80000 : {
		KEEP(*(.init))
		*(.text .text.*)
	}
    __text_end__ = .;
    . = ALIGN(4096);

	/* 
	 * Next we put the rodata .. C/C++ compilers store preset constants here.
	 */
	__rodata_start__ = .;
	.rodata : {
        *(.rodata .rodata.*)
   	}
    __rodata_end = .;
    . = ALIGN(4096);

	/* 
	 * Next we put the data.
	 */
	__data_start__ = .;
	.data : {
		*(.data .data.*)
	}
   	__data_end__ = .;
    . = ALIGN(4096);

	/* 
	 * Next we put the bss data .. C/C++ compilers produce this and needs to be zeroed by startup
	 */
	__bss_start__ = .;
	.bss (NOLOAD) : {
		*(.bss .bss.*)
 		*(COMMON .COMMON.*)
   	}
	__bss_end__ = .;
    . = ALIGN(4096);

	/* 
	 * Next is all the heap .. the space not used that the memory system will use
	 */
  	_end = .; PROVIDE (end = .);
	_heap_start = .;
	.heap  (NOLOAD) :	{
        . = . + HEAP_SIZE;
	}
    _heap_end = .;

	/*
	* Finally comes everything else. A fun trick here is to put all other 
	* sections into this section, which will be discarded by default.
	*/
	/DISCARD/ : {
		*(*)
	}
}
