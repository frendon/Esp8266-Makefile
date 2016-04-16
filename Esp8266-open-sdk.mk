########################################################################

BUILD_BASE = build
FW_BASE    = firmware

# Base directory for the compiler
XTENSA_TOOLS_ROOT 	?= $(ROOT)/xtensa-lx106-elf/bin

# base directory of the ESP8266 SDK package, absolute
SDK_BASE			?= $(ROOT)/sdk

#Esptool.py path and port
ESPTOOL				?= $(ROOT)/esptool/esptool.py
ESPPORT				?= /dev/ttyUSB0

# name for the target project
TARGET				= app

# which modules (subdirectories) of the project to include in compiling
MODULES				?= driver user
EXTRA_INCDIR		= include $(ROOT)/include/

# libraries used in this project, mainly provided by the SDK
LIBS = c gcc hal phy net80211 lwip wpa upgrade ssl main pp

# compiler flags using during compilation of source files
# Pedantic style
#CFLAGS       = -Os -g -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals  -D__ets__ -DICACHE_FLASH -pedantic -Wall -Wextra
CFLAGS				= -Os -g -O2 -Wpointer-arith -Wundef -Werror -Wl,-EL -fno-inline-functions -nostdlib -mlongcalls -mtext-section-literals  -D__ets__ -DICACHE_FLASH
CXXFLAGS			= $(CFLAGS) -fno-rtti -fno-exceptions
FLAGS_STD			= -std=gnu11
CXXFLAGS_STD		= -std=gnu++11

# linker flags used to generate the main object file
LDFLAGS				= -nostdlib -Wl,--no-check-sections -u call_user_start -Wl,-static

# linker script used for the above linkier step
LD_SCRIPT			= eagle.app.v6.ld

# various paths from the SDK used in this project
SDK_LIBDIR			= lib
SDK_LDDIR			= ld
SDK_INCDIR			= include include/json

# we create two different files for uploading into the flash
# these are the names and options to generate them
FW_FILE_1_ADDR		= 0x00000
FW_FILE_2_ADDR		= 0x40000

# select which tools to use as compiler, librarian and linker
CC			  		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
CXX			  		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-g++
AR			   		:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-ar
LD					:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-gcc
OBJCOPY 			:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-objcopy
OBJDUMP 			:= $(XTENSA_TOOLS_ROOT)/xtensa-lx106-elf-objdump


####
#### no user configurable options below here
####

SRC_DIR			:= $(MODULES)
BUILD_DIR		:= $(addprefix $(BUILD_BASE)/,$(MODULES))

SDK_LIBDIR		:= $(addprefix $(SDK_BASE)/,$(SDK_LIBDIR))
SDK_INCDIR		:= $(addprefix -I$(SDK_BASE)/,$(SDK_INCDIR))

SRC           := $(foreach sdir,$(SRC_DIR),$(wildcard $(sdir)/*.c*))
C_OBJ         := $(patsubst %.c,%.o,$(SRC))
CXX_OBJ       := $(patsubst %.cpp,%.o,$(C_OBJ))
OBJ           := $(patsubst %.o,$(BUILD_BASE)/%.o,$(CXX_OBJ))
LIBS          := $(addprefix -l,$(LIBS))
APP_AR        := $(addprefix $(BUILD_BASE)/,$(TARGET)_app.a)
TARGET_OUT    := $(addprefix $(BUILD_BASE)/,$(TARGET).out)

LD_SCRIPT     := $(addprefix -T$(SDK_BASE)/$(SDK_LDDIR)/,$(LD_SCRIPT))

INCDIR        := $(addprefix -I,$(SRC_DIR))
EXTRA_INCDIR  := $(addprefix -I,$(EXTRA_INCDIR))
MODULE_INCDIR := $(addsuffix /include,$(INCDIR))

FW_FILE_1     := $(addprefix $(FW_BASE)/,$(FW_FILE_1_ADDR).bin)
FW_FILE_2     := $(addprefix $(FW_BASE)/,$(FW_FILE_2_ADDR).bin)

V ?= $(VERBOSE)
ifeq ("$(V)","1")
Q :=
vecho := @true
else
Q := @
vecho := @echo
endif

vpath %.c $(SRC_DIR)
vpath %.cpp $(SRC_DIR)

define compile-objects
$1/%.o: %.c
	$(vecho) "CC $$<"
	$(Q) $(CC) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CFLAGS)  -c $$< -o $$@
$1/%.o: %.cpp
	$(vecho) "C+ $$<"
	$(Q) $(CXX) $(INCDIR) $(MODULE_INCDIR) $(EXTRA_INCDIR) $(SDK_INCDIR) $(CXXFLAGS)  -c $$< -o $$@
endef

.PHONY: all checkdirs clean
.PHONY: all checkdirs clean flash flashinit rebuild


all: checkdirs $(TARGET_OUT) 

$(FW_BASE)/%.bin: $(TARGET_OUT) | $(FW_BASE)
	$(vecho) "FW $(FW_BASE)/"

$(TARGET_OUT): $(APP_AR)
	$(vecho) "LD $@"
	$(Q) $(LD) -L$(SDK_LIBDIR) $(LD_SCRIPT) $(LDFLAGS) -Wl,--start-group $(LIBS) $(APP_AR) -Wl,--end-group -o $@
#	$(vecho) "------------------------------------------------------------------------------"
#	$(vecho) "Section info:"
#	$(Q) $(OBJDUMP) -h -j .data -j .rodata -j .bss -j .text -j .irom0.text $@
#$(vecho) "------------------------------------------------------------------------------"
	$(Q) $(ESPTOOL) elf2image $(TARGET_OUT) --output $(FW_BASE)/
	$(vecho) "------------------------------------------------------------------------------"
	$(vecho) "Generate 0x00000.bin and 0x40000.bin successully in folder $(FW_BASE)."
	$(vecho) "0x00000.bin-------->0x00000"
	$(vecho) "0x40000.bin-------->0x40000"
	$(vecho) "Done"


$(APP_AR): $(OBJ)
	$(vecho) "AR $@"
	$(Q) $(AR) cru $@ $^

checkdirs: $(BUILD_DIR) $(FW_BASE)

$(BUILD_DIR):
	$(Q) mkdir -p $@

$(FW_BASE):
	$(Q) mkdir -p $@


flash: all
	$(ESPTOOL) --port $(ESPPORT) write_flash $(FW_FILE_1_ADDR) $(FW_FILE_1) $(FW_FILE_2_ADDR) $(FW_FILE_2)


rebuild: clean all

clean:
	$(Q) rm -f $(APP_AR)
	$(Q) rm -f $(TARGET_OUT)
	$(Q) rm -rf $(BUILD_DIR)
	$(Q) rm -rf $(BUILD_BASE)
	$(Q) rm -rf $(FW_BASE)

$(foreach bdir,$(BUILD_DIR),$(eval $(call compile-objects,$(bdir))))
