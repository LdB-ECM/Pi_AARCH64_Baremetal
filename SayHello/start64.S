.section ".init", "ax", %progbits
.balign	4
.globl _start
_start:	
//"================================================================"
//  Initilize MPID/MPIDR registers for core 0
//"================================================================"
	mrs	x0, midr_el1
	mrs	x1, mpidr_el1
	msr	vpidr_el2, x0
	msr	vmpidr_el2, x1

//"================================================================"
//  Initialize Generic Timers for Core 0
//"================================================================"
	mrs	x0, cnthctl_el2
	orr	x0, x0, #0x3						/* Enable EL1 access to timers */
	msr	cnthctl_el2, x0
	msr	cntvoff_el2, xzr
	
//"================================================================"
//  Disable coprocessor traps for core 0
//"================================================================"
	mov	x0, #0x33ff
	msr	cptr_el2, x0						// Disable coprocessor traps to EL2
	msr	hstr_el2, xzr						// Disable coprocessor traps to EL2
	mov	x0, #3 << 20
	msr	cpacr_el1, x0						// Enable FP/SIMD at EL1

//"================================================================"
//  Initialize HCR_EL2 so EL1 is 64 bits for core 0
//"================================================================"
	mov	x0, #(1 << 31)						// 64bit EL1
	msr	hcr_el2, x0

//"================================================================"
//  Initialize SCTLR_EL1 for all Cores
//"================================================================"
    /*  RES1 bits (29,28,23,22,20,11) to 1
	 *  RES0 bits (31,30,27,21,17,13,10,6) +
	 *  UCI,EE,EOE,WXN,nTWE,nTWI,UCT,DZE,I,UMA,SED,ITD,
	 *  CP15BEN,SA0,SA,C,A,M to 0 */
	mov	x0, #0x0800
	movk	x0, #0x30d0, lsl #16
	orr    x0, x0, #(0x1 << 2)            // The C bit on (data cache). 
	orr    x0, x0, #(0x1 << 12)           // The I bit on (instruction cache)
	msr	sctlr_el1, x0

//"================================================================"
//  Return to the EL1_SP1 mode from EL2 for core 0
//"================================================================"
	mov	x0, #0x3c5							// EL1_SP1 | D | A | I | F
	msr	spsr_el2, x0						// Set spsr_el2 with settings
	adr	x0, .Lexit_el1						// Address to exit EL2
	msr	elr_el2, x0							// Set elevated return register
	eret									// Call elevated return
.Lexit_el1:

//"================================================================"
//  Auto-Detect Pi 3 or Pi4 by looking for SD card vendor ID
//"================================================================"
    ldr  x4, =0x3F000000                     // Pi3 peripheral Addr
    mov  x2, #0xfc  
    movk x2, #0x3f30, lsl #16                // Pi3 SD vendor ID is at 0x3F3000FC  
    ldr  w1, [x2]                            // w1 = value read
    and w1, w1, #0xFFFF0000                  // Clear lower 16 bits
    mov	w0, #0x99020000                     // Value to check
    cmp w0, w1
    beq .L_is_pi3
    ldr  x4, =0xFE000000                     // Pi4 peripheral Addr
.L_is_pi3:
    adr     x2, Pi_Peripheral_Addr         // Address to store value
    str     x4, [x2]                        // Hold the value   
//"================================================================"
//  About to go to into C kernel clear BSS (Core0 only)
//"================================================================"
	ldr x3, =__bss_end__
    ldr x0, =__bss_start__
.Lbss_zero_loop:
	cmp	x0, x3
	beq	.Lbss_cleared
	str	wzr, [x0], 4
    b .Lbss_zero_loop
.Lbss_cleared:

//"================================================================"
// Finally that all done Core0 jumps to the C compiler entry point
//"================================================================"
    mov sp, 0x80000                         // Simply set SP to 0x80000 because it is free below that
	b main									// Jump out to C kernel 

/*================================================================"
      Just safety incase C code ever returns back
"================================================================*/
.Lhang:
	b .Lhang
.ltorg



/*================================================================"
  EXTERNAL FUNCTION: bool InitGraph (uint32_t xres, uint32_t yres, uint32_t depth);
"================================================================*/
.section .text.InitGraph, "ax", %progbits
.balign	4
.globl InitGraph;		
.type InitGraph, %function
InitGraph:
    
    adr     x3, mbreq                               // Address of mbreq data 
    /*" If InitGraph had already run we need to clear responses back to zero "*/
    str      wzr, [x3, #4]                          // Zero mailbox response 
    str      wzr, [x3, #(.L_Tag0 - mbreq + 8)]      // Zero tag0  response
    str      wzr, [x3, #(.L_Tag1 - mbreq + 8)]      // Zero tag1  response
    str      wzr, [x3, #(.L_Tag2 - mbreq + 8)]      // Zero tag2  response
    str      wzr, [x3, #(.L_Tag3 - mbreq + 8)]      // Zero tag3  response
    str      wzr, [x3, #(.L_Tag4 - mbreq + 8)]      // Zero tag4  response
    str      wzr, [x3, #(.L_Tag5 - mbreq + 8)]      // Zero tag5  response
    /*" Now set the values the caller has asked for"*/
    str      w0, [x3, #(.L_Tag0 - mbreq + 12)]      // Set Tag0 width value
    str      w1, [x3, #(.L_Tag0 - mbreq + 16)]      // Set Tag0 height value
    str      w0, [x3, #(.L_Tag1 - mbreq + 12)]      // Set Tag1 width value
    str      w1, [x3, #(.L_Tag1 - mbreq + 16)]      // Set Tag1 height value
    str      w2, [x3, #(.L_Tag3 - mbreq + 12)]      // Set Tag3 colour depth

    orr     w2, w3, #8                              // Encoded request address + channel number.
    adr     x1, Pi_Peripheral_Addr                  // Address of Pi Peripheral address
    ldr     x1, [x1]                                // Load peripheral address detected
    add     x1, x1, #0xb000
    add     x1, x1, #0x880
 .L_waitmbc:                                        // Wait for mailbox FULL flag to be clear.
    ldr     w0, [x1, 0x38]                          // w0 = mailbox status.
    tbnz    w0, #31, .L_waitmbc                     // If FULL flag set (bit 31), try again...
    str     w2, [x1, 0x20]                          // Write request address / channel number to mailbox write register.
 .L_wait_mbe:                                       // Wait for mailbox EMPTY flag to be clear.
    ldr     w0, [x1, 0x18]                          // w0 = mailbox status.
    tbnz    w0, #30, .L_wait_mbe                    // If EMPTY flag set (bit 30), try again...
    ldr     w0, [x1]                                // w0 = message request address + channel number.
    cmp     w2, w0                                  // See if the message is for us.
    b.ne    .L_wait_mbe                             // If not, try again.
  
    ldr     w0, [x3, #4]                            // Check the response
    tbnz    w0, #31, .L_call_success                // If flag set (bit 31) response success
    mov x0, #1                                      // Failure return 1
    ret
.L_call_success:
    ldr     w0, [x3, #(.L_Tag4 - mbreq + 12)]       // w0 = allocated framebuffer address
    and     w0, w0, #0x3fffffff                     // Clear upper bits beyond addressable memory
    ldr     w1, [x3, #(.L_Tag5 - mbreq + 12)]       // w1 = pitch (bytes per horizontal line of framebuffer)
    adr x2, Pi_Frame_Buffer_Addr
    str  w0, [x2]
    adr x2, Pi_Frame_Buffer_Pitch
    str  w1, [x2]
    mov x0, xzr                                     // Sucess return 0
    ret

# Memory block for mailbox call
.section ".data.intgraph", "aw"
.balign 16
mbreq:
.4byte mbreq_end - mbreq        // Buffer size
.4byte 0                        // Request/response code
.L_Tag0:
    .4byte 0x48003              // Tag 0 - Set Screen Size
    .4byte 8                    //   value buffer size
    .4byte 0                    //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
    .4byte 800                  //   request: width                response: width
    .4byte 600                  //   request: height               response: height
.L_Tag1:
    .4byte 0x48004              // Tag 1 - Set Virtual Screen Size
    .4byte 8                    //   value buffer size
    .4byte 0                    //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
    .4byte 800                  //   request: width                response: width
    .4byte 600                  //   request: height               response: height
.L_Tag2:
    .4byte 0x48009              // Tag 2 - Set Virtual Offset
    .4byte 8                    //   value buffer size
    .4byte 0                    //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
    .4byte 0                    //   request: x offset             response: x offset
    .4byte 0                    //   request: y offset             response: y offset
.L_Tag3:
    .4byte 0x48005              // Tag 3 - Set Colour Depth
    .4byte 4                    //   value buffer size
    .4byte 0                    //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
    .4byte 32                   //   request: bits per pixel       response: bits per pixel
.L_Tag4:
    .4byte 0x40001              // Tag 4 - Get (Allocate) Buffer
    .4byte 8                    //   value buffer size (response > request, so use response size)
    .4byte 0                    //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
    .4byte 4096                 //   request: alignment in bytes   response: frame buffer base address
    .4byte 0                    //   request: padding              response: frame buffer size in bytes
.L_Tag5:
    .4byte 0x40008              // Tag 5 - Get Pitch (bytes per line)
    .4byte 4                    //   value buffer size
    .4byte 0                    //   request: should be 0          response: 0x80000000 (success) / 0x80000001 (failure)
    .4byte 0                    //   request: padding              response: bytes per line
.4byte 0                        // End Tags
mbreq_end:

.section ".data.framebuffer", "aw"
.balign 16

.globl Pi_Peripheral_Addr;
Pi_Peripheral_Addr : .8byte 0;

.globl Pi_Frame_Buffer_Addr;
Pi_Frame_Buffer_Addr : .4byte 0;	

.globl Pi_Frame_Buffer_Pitch;
Pi_Frame_Buffer_Pitch : .4byte 0;	
