# If cross compiling from windows use native GNU-Make 4.2.1
# https://sourceforge.net/projects/ezwinports/files/
# download "make-4.2.1-without-guile-w32-bin.zip" and set it on the enviroment path
# There is no need to install cygwin or any of that sort of rubbish

ifeq ($(OS), Windows_NT)
	#WINDOWS USE THESE DEFINITIONS
	RM = -del /q
	SLASH = \\
else
	#LINUX USE THESE DEFINITIONS
	RM = -rm -f
	SLASH = /
endif 

# CHANGE THIS TO MATCH GCC DIRECTORY LOCATION ON YOUR MACHINE + FIRST PART OF YOUR GCC EXE
ARMGNU = d:/gcc/gcc-linaro-7.4.1-2019.02-i686-mingw32_aarch64-elf/bin/aarch64-elf

CFLAGS = -Wall -O1 -mcpu=cortex-a53+fp+simd -ffreestanding -nostartfiles -std=c11 -mstrict-align -fno-tree-loop-vectorize -fno-tree-slp-vectorize -Wno-nonnull-compare
LINKERFILE = rpi64.ld
BOOTSTUB = Start64.S
IMGFILE = kernel8.img

# The directory in which source files are stored.
SOURCE = ${CURDIR}
BUILD = Build

# The name of the assembler listing file to generate.
LIST = kernel.list

# The name of the map file to generate.
MAP = kernel.map

ALL: kernel.elf

# The names of all object files that must be generated. Deduced from the 
# assembly code files in source.

ASMOBJS = $(patsubst $(SOURCE)/%.S,$(BUILD)/%.o,$(BOOTSTUB))
CFILES = $(wildcard $(SOURCE)/*.c)

COFILES := $(patsubst %.c,$(BUILD)/%.o, $(notdir $(CFILES)))

$(BUILD)/%.o: $(SOURCE)/%.s
	$(ARMGNU)-gcc -MMD -MP -g $(CFLAGS) -c  $< -o $@

$(BUILD)/%.o: $(SOURCE)/%.S
	$(ARMGNU)-gcc -MMD -MP -g $(CFLAGS) -c  $< -o $@

$(COFILES): $(CFILES)
	@echo Compiling $(CODE_ARCH) $(filter %/$(patsubst %.o,%.c,$(notdir $@)), $(CFILES)) ==^> $@
	$(ARMGNU)-gcc -MMD -MP -g $(CFLAGS) $(filter %/$(patsubst %.o,%.c,$(notdir $@)), $(CFILES)) -c -o $@

kernel.elf: $(ASMOBJS) $(COFILES) 
	$(ARMGNU)-gcc $(CFLAGS) $(ASMOBJS) $(COFILES) -T $(LINKERFILE) -Wl,--build-id=none --specs=nosys.specs -o kernel.elf
	@echo ELF compiled (kernel.elf)
	$(ARMGNU)-objdump -d kernel.elf > $(LIST)
	@echo DISASSEMBLE output ($(LIST))
	$(ARMGNU)-objcopy kernel.elf -O binary DiskImg/$(IMGFILE)
	@echo IMG file output (DiskImg/$(IMGFILE))
	$(ARMGNU)-nm -n kernel.elf > $(MAP)
	@echo MAP file output ($(MAP))

# we want silent
.SILENT: 

# cleanup temp files
clean:
	$(RM) $(MAP) 
	$(RM) kernel.elf 
	$(RM) $(LIST) 
	$(RM) $(BUILD)$(SLASH)*.o 
	$(RM) $(BUILD)$(SLASH)*.d 
	echo CLEAN COMPLETED
.PHONY: clean

