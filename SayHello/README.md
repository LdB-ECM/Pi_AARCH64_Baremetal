
# SayHello ... AARCH64 for Pi3 and Pi4
As per usual you can simply copy the files in the **DiskImg** directory onto a formatted SD card and place in Pi3 or Pi4 to test

[Details:](https://github.com/LdB-ECM/Docs_and_Images/blob/master/Documentation/COMPILING%20AARCH64%20CODE.md)  on how to compile AARCH64 baremetal if you need
>
>
>This code will simply kick the screen into 800x600 with 32 bit colour depth, fill the screen blue and put up two lines of text ("Hello World", "The End").
>
>There are a number of important files to discuss
>
>[BOOTSTUB (start64.S):](start64.S)
>
>​	The bootstub file is where Core0 will be delivered to start execution of our baremetal program. The entry point in AARCH64 is normally 0x80000 with the Core in EL2 mode. This can be varied in several ways by CONFIG.TXT on the SD Card but is outside discussion here.
>
>
>
>​	The initial code will do some basic things with Core0 setting EL1 to 64Bits and bringing the FPU online before dropping the core down to run in EL1 mode. EL1 is the normal level for a general OS to run and again we wont discuss that further here. 
>
>
>
>​	Next it runs a small autodetect check on address 0x3F3000FC which is the SD Card Vendor ID if that value is not 0x9902xxxx it knows we must be on a Pi4. That detection sequence will set a global value provided on the interface called **Pi_Peripheral_Addr** which is the address of the peripherals, it will be 0x3F000000 on a Pi3 and 0xFE000000 on a Pi4.
>
> 
>
> 	Finally the core will clear the ([BSS](https://en.wikipedia.org/wiki/.bss)) segment of the code, sets the Stack Pointer to 0x80000 which is out of the way before then doing a jump to the C code start point **int main(void)**. So then everything switches to C code and you just follow the code there as normal. 
>
>
>
>​	There is one additional piece of code not run which is called InitGraph and it is a small piece of code that will initialize the Video Screen and set two global accessible values.  The first value is called **Pi_Frame_Buffer_Addr** and it is the address to write data to put pixels on the screen. The second value is called  **Pi_Frame_Buffer_Pitch**  and it is the number of bytes at that address between vertical lines at that address. These two are required to be able to draw graphics primitives.
>
>

>[LINKER DIRECTIVE (rpi64.ld):](rpi64.ld).
>
>   The linker directive file organizes where things are placed at the link stage and it puts some special labels we may need. It will make what is the typical loading pattern for the ARM CPU. It starts by placing all executable code in a section called .TEXT which starts at 0x80000. Next follows all the constant data in a section called .RODATA . Then follows all static data in a section called .DATA. The BSS section we cleared at startup follows behind that and finally all the memory not used is defined into a .HEAP section



>[C CODE FILE START (main.c):](main.c).
>
>   In the sample main.c code the code starts by calling InitGraph with the screen settings desired as provided 800 x 600 with 32 bit colour depth. You may change the X and Y resolution as required but you must stay in 32 bit colour mode simply because the primitives I provided are only 32 Bit colour depth they won't work on a different depth.  For Text a bitmap font is required which is defined in Font16x8.h and included at top of main.c. The program then clears the screen blue  before writing the two messages on screen and then dead looping.
>
>

#### **Congratulations you now have Graphics on Screen In AARCH64 BareMetal**
