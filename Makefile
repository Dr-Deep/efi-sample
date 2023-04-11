#!/usr/bin/env gmake
# by @Dr.Deep

TARGET		= $(OBJDIR)/BOOTX64.EFI
BOOTROM		= /usr/local/share/uefi-firmware/BHYVE_UEFI.fd # sysutlis/bhyve-firmware

#
DISK_IMG	= ./disk.img
DISK_IMG_DEV= md99
DISK_IMG_SZ = 64M

#
CC			= clang
LD			= lld-link15
LIBS		= 
INCLUDES	= -I efi

#
ERRORFLAGS	= -Wall -Wextra
OTHERFLAGS	= -O3 -std=c99

#
OBJDIR		= build
SRCDIR		= src
EXTRAFLAGS	= $(INCLUDES) $(ERRORFLAGS) $(OTHERFLAGS)
CFLAGS		= -target x86_64-pc-win32-coff -fno-stack-protector -fshort-wchar -mno-red-zone
LFLAGS		= -subsystem:efi_application -nodefaultlib -dll

CFILES		= $(wildcard $(SRCDIR)/*.c)
OBJS		= $(OBJDIR)/efi_main.o $(OBJDIR)/main.o


.PHONY: all
all: $(TARGET) vm_create


$(TARGET): $(OBJDIR) $(OBJS)
	$(LD) $(LFLAGS) -entry:efi_main $(OBJDIR)/*.o -out:$@

$(OBJDIR):
	@mkdir -p $@

$(OBJDIR)/%.o: $(SRCDIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(DISK_IMG): $(TARGET)
	truncate -s $(DISK_IMG_SZ) $(DISK_IMG)
	@echo "[!] The following commands need root."
	doas sh -c 'mdconfig -a -u ${DISK_IMG_DEV} -t vnode -f ${DISK_IMG} &&\
	gpart create -s GPT ${DISK_IMG_DEV} &&\
	gpart add -t ms-basic-data ${DISK_IMG_DEV} &&\
	newfs_msdos -F 16 /dev/${DISK_IMG_DEV}p1 &&\
	mount -t msdosfs /dev/${DISK_IMG_DEV}p1 /mnt &&\
	mkdir -p /mnt/EFI/BOOT &&\
	cp ${TARGET} /mnt/EFI/BOOT/BOOTX64.EFI &&\
	umount /mnt'


clean: vm_destroy
	rm -f $(OBJDIR)/*


vm_create: vm_destroy $(DISK_IMG)
	@echo "[!] The following commands need root."
	doas bhyve -c 1 -m 256M -H -D \
		-s 0,hostbridge \
		-s 1,ahci-hd,/dev/$(DISK_IMG_DEV) \
		-s 2,lpc \
		-l com1,stdio \
		-l bootrom,$(BOOTROM) \
		$(TARGET)


vm_destroy:
	if [ -f "/dev/$(DISK_IMG_DEV)" ]; then \
		@echo "[!] The following commands need root."; \
		doas mdconfig -d -u $(DISK_IMG_DEV); \
	fi
	
	rm -f $(DISK_IMG)
