//https://github.com/utshina/uefi-simple/blob/master/main.c

#include "efi.h"

EFI_STATUS EFIAPI efi_main (IN EFI_HANDLE ImageHandle, IN EFI_SYSTEM_TABLE *SystemTable) {
    SystemTable->ConOut->OutputString(SystemTable->ConOut, L"DEEPCRACK!\n");
    //while(1);
    main()
    return EFI_SUCCESS;
}
