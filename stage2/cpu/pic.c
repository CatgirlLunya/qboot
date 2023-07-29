#include "pic.h"

// Uses the Interrupt Mask Register/OCW1, specified in the PCH datasheet for pretty much any series I can find either at 12.4.7 or 13.4.7 or anywhere else
// 13.4.7 in https://www.intel.com/content/dam/www/public/us/en/documents/datasheets/9-series-chipset-pch-datasheet.pdf
// Code just writes 0b11111111 to both registers, masking all interrupts
void PICDisable(void) {
    outb(0xA1, 0xFF);
    outb(0x21, 0xFF);
}
