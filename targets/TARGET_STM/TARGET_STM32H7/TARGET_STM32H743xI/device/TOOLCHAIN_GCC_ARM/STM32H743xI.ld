/*
*****************************************************************************
** Linker script for STM32H743XIHx
*****************************************************************************
*/

#if !defined(MBED_APP_START)
    #define MBED_APP_START 0x08000000
#endif

#if !defined(MBED_APP_SIZE)
    #define MBED_APP_SIZE 2048K
#endif

D1_START = 0x24000000;
D1_SIZE  = 512K;

NVIC_NUM_VECTORS  = 166;
NVIC_VECTORS_SIZE = (NVIC_NUM_VECTORS * 4);

DTCMRAM_START = 0x20000000 + NVIC_VECTORS_SIZE;
DTCMRAM_SIZE  = 128K - NVIC_VECTORS_SIZE;

M_CRASH_DATA_RAM_SIZE = 0x100;

/* Specify the memory areas */
MEMORY
{
    FLASH   (rx ): ORIGIN = MBED_APP_START, LENGTH = MBED_APP_SIZE
    DTCMRAM (xrw): ORIGIN = DTCMRAM_START,  LENGTH = DTCMRAM_SIZE
    RAM_D1  (xrw): ORIGIN = D1_START,       LENGTH = D1_SIZE
    RAM_D2  (xrw): ORIGIN = 0x30000000,     LENGTH = 288K
    RAM_D3  (xrw): ORIGIN = 0x38000000,     LENGTH = 64K
    ITCMRAM (xrw): ORIGIN = 0x00000000,     LENGTH = 64K
}

/* Entry Point */
ENTRY(Reset_Handler)

/* Highest address of the user mode stack */
_estack = D1_START + D1_SIZE; /* end of RAM */
/* Generate a link error if heap and stack don't fit into RAM */
_Min_Heap_Size = 128K;  /* required amount of heap  */
_Min_Stack_Size = 128K; /* required amount of stack */

/* Define output sections */
SECTIONS
{
    .text :
    {
        KEEP(*(.isr_vector))
        . = ALIGN(4);
        *(.text*)
        *(.glue_7) /* glue arm to thumb code */
        *(.glue_7t) /* glue thumb to arm code */
        KEEP(*(.init))
        KEEP(*(.fini))

        /* .ctors */
        *crtbegin.o(.ctors)
        *crtbegin?.o(.ctors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .ctors)
        *(SORT(.ctors.*))
        *(.ctors)

        /* .dtors */
        *crtbegin.o(.dtors)
        *crtbegin?.o(.dtors)
        *(EXCLUDE_FILE(*crtend?.o *crtend.o) .dtors)
        *(SORT(.dtors.*))
        *(.dtors)

        *(.rodata*)

        KEEP(*(.eh_frame*))

        . = ALIGN(4);
        _etext = .; /* define a global symbols at end of code */
    } > FLASH

    .ARM.extab :
    {
        *(.ARM.extab* .gnu.linkonce.armextab.*)
    } > FLASH

    __exidx_start = .;
    .ARM.exidx :
    {
        *(.ARM.exidx* .gnu.linkonce.armexidx.*)
    } > FLASH
    __exidx_end = .;

    __etext = .;
    _sidata = .;

    .crash_data_ram :
    {
        . = ALIGN(8);
        __CRASH_DATA_RAM__ = .;
        __CRASH_DATA_RAM_START__ = .; /* Create a global symbol at data start */
        KEEP(*(.keep.crash_data_ram))
        *(.m_crash_data_ram)     /* This is a user defined section */
        . += M_CRASH_DATA_RAM_SIZE;
        . = ALIGN(8);
        __CRASH_DATA_RAM_END__ = .; /* Define a global symbol at data end */
    } > DTCMRAM

    .data : AT (__etext)
    {
        __data_start__ = .;
        _sdata = .;
        *(vtable)
        *(.data*)

        . = ALIGN(8);
        /* preinit data */
        PROVIDE_HIDDEN (__preinit_array_start = .);
        KEEP(*(.preinit_array))
        PROVIDE_HIDDEN (__preinit_array_end = .);

        . = ALIGN(8);
        /* init data */
        PROVIDE_HIDDEN (__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE_HIDDEN (__init_array_end = .);

        . = ALIGN(8);
        /* finit data */
        PROVIDE_HIDDEN (__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE_HIDDEN (__fini_array_end = .);

        KEEP(*(.jcr*))
        . = ALIGN(8);
        /* All data end */
        __data_end__ = .;
        _edata = .;
    } > RAM_D1

    .bss :
    {
        . = ALIGN(8);
        __bss_start__ = .;
        _sbss = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(8);
        __bss_end__ = .;
        _ebss = .;
    } > RAM_D1

    /* User_heap_stack section, used to check that there is enough RAM left */
    ._user_heap_stack :
    {
        . = ALIGN(8);
        __end__ = .;
        PROVIDE ( end = __end__ );
        PROVIDE ( _end = __end__ );
        . = . + _Min_Heap_Size;
        __HeapLimit = .;
        . = . + _Min_Stack_Size;
        . = ALIGN(8);
    } > RAM_D1

    .lwip_sec (NOLOAD) : {
        . = ABSOLUTE(0x30040000);
        *(.RxDecripSection) 

        . = ABSOLUTE(0x30040060);
        *(.TxDecripSection)

        . = ABSOLUTE(0x30040200);
        *(.RxArraySection) 
    } > RAM_D2 AT > FLASH

    __StackTop = _estack;
    __StackLimit = __StackTop - _Min_Stack_Size;
    PROVIDE(__stack = __StackTop);

    /* Remove information from the standard libraries */
    /DISCARD/ :
    {
        libc.a ( * )
        libm.a ( * )
        libgcc.a ( * )
    }

    .ARM.attributes 0 : { *(.ARM.attributes) }

    /* Check if data + heap + stack exceeds RAM limit */
    ASSERT(__StackLimit >= __HeapLimit, "region RAM overflowed with stack")
}
