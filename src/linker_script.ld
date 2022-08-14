/* Linker script to configure memory regions. */

SEARCH_DIR(.)
GROUP(-lgcc -lc -lnosys)

MEMORY
{
  /*FLASH (rx) : ORIGIN = 0x00000000, LENGTH = 0x100000*/
  FLASH (rx) : ORIGIN = 0x10000, LENGTH = 0xf0000
  EXTFLASH (rx) : ORIGIN = 0x12000000, LENGTH = 0x8000000
  RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 0x40000
  CODE_RAM (rwx) : ORIGIN = 0x800000, LENGTH = 0x40000
}

/*
MEMORY
{
  FLASH (rx) : ORIGIN = 0x10000, LENGTH = 0xf0000
  RAM_NVIC (rwx) : ORIGIN = 0x20000000, LENGTH = 0x100
  RAM_CRASH_DATA (rwx) : ORIGIN = (0x20000000 + 0x100), LENGTH = 0x100
  RAM (rwx) : ORIGIN = ((0x20000000 + 0x100) + 0x100), LENGTH = (0x40000 - (0x100 + 0x100))
}
*/


INCLUDE "nrf_common.ld"
