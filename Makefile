#-------------------------------------------------------------------------------
# Copyright (c) 2010-2013, Jean-David Gadina - www.xs-labs.com
# All rights reserved.
# 
# XEOS Software License - Version 1.0 - December 21, 2012
# 
# Permission is hereby granted, free of charge, to any person or organisation
# obtaining a copy of the software and accompanying documentation covered by
# this license (the "Software") to deal in the Software, with or without
# modification, without restriction, including without limitation the rights
# to use, execute, display, copy, reproduce, transmit, publish, distribute,
# modify, merge, prepare derivative works of the Software, and to permit
# third-parties to whom the Software is furnished to do so, all subject to the
# following conditions:
# 
#       1.  Redistributions of source code, in whole or in part, must retain the
#           above copyright notice and this entire statement, including the
#           above license grant, this restriction and the following disclaimer.
# 
#       2.  Redistributions in binary form must reproduce the above copyright
#           notice and this entire statement, including the above license grant,
#           this restriction and the following disclaimer in the documentation
#           and/or other materials provided with the distribution, unless the
#           Software is distributed by the copyright owner as a library.
#           A "library" means a collection of software functions and/or data
#           prepared so as to be conveniently linked with application programs
#           (which use some of those functions and data) to form executables.
# 
#       3.  The Software, or any substancial portion of the Software shall not
#           be combined, included, derived, or linked (statically or
#           dynamically) with software or libraries licensed under the terms
#           of any GNU software license, including, but not limited to, the GNU
#           General Public License (GNU/GPL) or the GNU Lesser General Public
#           License (GNU/LGPL).
# 
#       4.  All advertising materials mentioning features or use of this
#           software must display an acknowledgement stating that the product
#           includes software developed by the copyright owner.
# 
#       5.  Neither the name of the copyright owner nor the names of its
#           contributors may be used to endorse or promote products derived from
#           this software without specific prior written permission.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT OWNER AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
# THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
# PURPOSE, TITLE AND NON-INFRINGEMENT ARE DISCLAIMED.
# 
# IN NO EVENT SHALL THE COPYRIGHT OWNER, CONTRIBUTORS OR ANYONE DISTRIBUTING
# THE SOFTWARE BE LIABLE FOR ANY CLAIM, DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
# EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
# PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
# OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
# WHETHER IN ACTION OF CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF OR IN CONNECTION WITH
# THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE, EVEN IF ADVISED
# OF THE POSSIBILITY OF SUCH DAMAGE.
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
# @author           Jean-David Gadina
# @copyright        (c) 2010-2015, Jean-David Gadina - www.xs-labs.com
#-------------------------------------------------------------------------------

include make/Config.mk
include make/Targets.mk

.PHONY: toolchain

.NOTPARALLEL:

PROMPT  := XEOS
DEPS    := 
FILES   := 
TARGETS := tools source

all: build-sub kernel floppy
	
	@:

clean: clean-sub obj-clean
	
	@:

distclean: distclean-sub deps-clean
	
	@:
	
toolchain:
	
	$(call PRINT,$(COLOR_CYAN)Building the XEOS compiler toolchain$(COLOR_NONE))
	@cd toolchain && $(MAKE)


kernel: _EXEC = $(foreach _A,$(ARCHS),$(patsubst %,$(DIR_BUILD)%/xeos$(EXT_EXEC),$(_A)))
kernel: $$(_EXEC)
	
	@:

$(DIR_BUILD)%$(EXT_EXEC): _LIBS       = c99 posix pthread iconv system blocks dispatch objc elf
$(DIR_BUILD)%$(EXT_EXEC): _CORE       = acpi xeos
$(DIR_BUILD)%$(EXT_EXEC): _ARCH       = $(firstword $(subst /, ,$*))
$(DIR_BUILD)%$(EXT_EXEC): _CORE_OBJ   = $(foreach _C,$(_CORE),$(patsubst %,source/core/%/build/$(_ARCH)$(EXT_OBJ),$(_C)))
$(DIR_BUILD)%$(EXT_EXEC): _LD         = $(LD_$(_ARCH))
$(DIR_BUILD)%$(EXT_EXEC): _FLAGS      = -T source/core/linker.ld $(ARGS_LD_$(_ARCH))
$(DIR_BUILD)%$(EXT_EXEC): _FLAGS_LIBS = -Lsource/lib/build/$(_ARCH) -static $(foreach _L,$(_LIBS),$(addprefix -l,$(_L)))
$(DIR_BUILD)%$(EXT_EXEC): $$(shell mkdir -p $$(DIR_BUILD)$$(_ARCH)) FORCE
	
	$(call PRINT_FILE,$(_ARCH),$(COLOR_CYAN)Linking the kernel file$(COLOR_NONE),$(COLOR_YELLOW)$(notdir $@)$(COLOR_NONE))
	@$(_LD) $(_FLAGS) -o $@ $(_CORE_OBJ) $(_FLAGS_LIBS)

floppy: floppy_$(BUILD_HOST) FORCE
	
	@:

floppy_unknown:
	
	$(call PRINT,$(COLOR_RED)Boot floppy generation not implemented for the current host: $(COLOR_NONE)$(COLOR_YELLOW)$(BUILD_HOST)$(COLOR_NONE))

floppy_mac_dmg: _FLOPPY_DMG := $(DIR_BUILD)tmp/boot.dmg
floppy_mac_dmg: _FLOPPY_IMG := $(DIR_BUILD)boot.img
floppy_mac_dmg: _MBR        := source/boot/bios/build/mbr.bin
floppy_mac_dmg: $$(shell mkdir -p $$(DIR_BUILD)tmp) FORCE
	
	$(call PRINT,$(COLOR_CYAN)Creating a fresh floppy image \(UDIF FAT12\): $(COLOR_NONE)$(COLOR_YELLOW)$(_FLOPPY_DMG)$(COLOR_NONE))
	@hdiutil create -ov -type UDIF -sectors 2880 -fs "MS-DOS FAT12" -volname "XEOS" $(_FLOPPY_DMG) > /dev/null
	
	$(call PRINT,$(COLOR_CYAN)Installing the XEOS Master Boot Record \(MBR\): $(COLOR_NONE)$(COLOR_YELLOW)$(_MBR)$(COLOR_NONE))
	@dd conv=notrunc if=$(_MBR) of=$(_FLOPPY_DMG) > /dev/null 2>&1

floppy_mac: floppy_mac_dmg
floppy_mac: _FLOPPY_DMG    := $(DIR_BUILD)tmp/boot.dmg
floppy_mac: _FLOPPY_IMG    := $(DIR_BUILD)boot.img
floppy_mac: _FLOPPY_DEVICE  = $(shell hdid -nobrowse -nomount $(_FLOPPY_DMG))
floppy_mac: $$(shell mkdir -p $$(DIR_BUILD)mount) FORCE
	
	$(call PRINT,$(COLOR_CYAN)Mounting the boot floppy image: $(COLOR_NONE)$(COLOR_YELLOW)$(_FLOPPY_DEVICE)$(COLOR_NONE))
	@mount -t msdos $(_FLOPPY_DEVICE) $(DIR_BUILD)mount
	
	$(call PRINT,$(COLOR_CYAN)Copying the second stage bootloader to the boot floppy$(COLOR_NONE))
	@cp source/boot/bios/build/boot.bin $(DIR_BUILD)mount/BOOT.BIN
	
	$(call PRINT,$(COLOR_CYAN)Copying the XEOS kernel to the boot floppy$(COLOR_NONE))
	@cp build/i386/xeos.elf $(DIR_BUILD)mount/XEOS32.ELF
	@cp build/x86_64/xeos.elf $(DIR_BUILD)mount/XEOS64.ELF
	
	$(call PRINT,$(COLOR_CYAN)Unmounting the boot floppy image: $(COLOR_NONE)$(COLOR_YELLOW)$(_FLOPPY_DEVICE)$(COLOR_NONE))
	@umount $(_FLOPPY_DEVICE) > /dev/null
	
	$(call PRINT,$(COLOR_CYAN)Detaching the boot floppy image: $(COLOR_NONE)$(COLOR_YELLOW)$(_FLOPPY_DEVICE)$(COLOR_NONE))
	@hdiutil detach $(_FLOPPY_DEVICE) > /dev/null
	
	$(call PRINT,$(COLOR_CYAN)Converting the floppy image: $(COLOR_NONE)$(COLOR_YELLOW)$(_FLOPPY_IMG)$(COLOR_NONE))
	@hdiutil convert -ov $(_FLOPPY_DMG) -format Rdxx -o $(_FLOPPY_IMG) > /dev/null
