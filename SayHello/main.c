#include <stdbool.h>
#include <stdint.h>
#include "Font8x16.h"
/* System font is 8 wide and 16 height as per include above */
#define BitFontHt 16
#define BitFontWth 8

/* These are defined and set in Start64.S .. hence extern */
extern uint64_t Pi_Peripheral_Addr;
extern uint32_t Pi_Frame_Buffer_Addr;
extern uint32_t Pi_Frame_Buffer_Pitch;
extern bool InitGraph (uint32_t xres, uint32_t yres, uint32_t depth);

/* Graphics position and colour */
static uint16_t grPosX = 0;
static uint16_t grPosY = 0;
static uint32_t BkColor = 0;
static uint32_t TxtColor = 0x00FFFFFF;

static void ClearArea32 (uint16_t x1, uint16_t y1, uint16_t x2, uint16_t y2, uint32_t color) 
{
	uint32_t* __attribute__((aligned(4))) video_wr_ptr = (uint32_t*)(uintptr_t)(Pi_Frame_Buffer_Addr + (grPosY * Pi_Frame_Buffer_Pitch) + (grPosX * 4));
	for (uint16_t y = 0; y < (y2 - y1); y++)						// For each y line
	{
		for (uint16_t x = 0; x < (x2 - x1); x++) 					// For each x between x1 and x2
		{
			video_wr_ptr[x] = color;								// Write the colour
		}
		video_wr_ptr += (Pi_Frame_Buffer_Pitch / 4);				// Next line down
	}
}

static void WriteChar32 (uint8_t ch, bool transparent)
{
	uint32_t* __attribute__((aligned(4))) video_wr_ptr = (uint32_t*)(uintptr_t)(Pi_Frame_Buffer_Addr + (grPosY * Pi_Frame_Buffer_Pitch) + (grPosX * 4));
	uint8_t* bp = (uint8_t*)&BitFont[(ch * 16)];					// Load font bitmap pointer
	for (uint16_t y = 0; y < BitFontHt; y++)						// For each line in height
	{
		uint8_t b = *bp++;											// Fetch font data byte
		for (uint16_t x = 0; x < BitFontWth; x++)
		{
			uint32_t col = ((b & 0x80) == 0x80) ? TxtColor : BkColor;
			if (!transparent || ((b & 0x80) == 0x80)) video_wr_ptr[x] = col;// Write pixel
			b = b << 1;												// Shift 1 bit left
			if ((((x + 1) % 8) == 0) && (x + 1) < BitFontWth)
				b = *bp++;											// Fetch next byte
		}
		video_wr_ptr += (Pi_Frame_Buffer_Pitch / 4);				// Next line down
	}
}

void SemiHost_WriteChar(char Ch) 
{
	switch (Ch) 
	{
		case '\r': 								// Carriage return character
			grPosX  = 0;						// Cursor back to line start
			break;
		case '\n': 								// New line character
			grPosX = 0;							// Cursor back to line start
			grPosY += BitFontHt ;				// Increment cursor down a line
			break;
		default: 								// All other characters
			WriteChar32(Ch, false);				// Write the character to graphics screen
			grPosX += BitFontWth ;				// Cursor.x forward one character
			break;
	}
}

void SemiHost_Write(char* txt) 
{
	while (txt && *txt)
    {
		SemiHost_WriteChar(*txt);
        txt++;
    }
}

/* If someone is dumb enough to use malloc give them a fighting chance it will work */
#include <sys/types.h>
extern char _end;
static char* heap_end = &_end;
caddr_t __attribute__((weak)) _sbrk(int incr)
{
	char* prev_heap_end = heap_end;
	heap_end += incr;
	return (caddr_t)prev_heap_end;
}



int main (void)
{
     InitGraph(800, 600, 32); 
	 ClearArea32(0, 0, 800, 600, 0xFF);
        
     SemiHost_Write("Hello World\r\n");

     SemiHost_Write("The End\r\n");;
     while (1) {};
     return 0;
}






