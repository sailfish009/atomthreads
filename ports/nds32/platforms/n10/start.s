# 1 "start.S"
# 1 "<built-in>"
# 1 "<command-line>"
# 1 "start.S"
!********************************************************************************************************
!
! (c) Copyright 2005-2014, Andes Techonology
! All Rights Reserved
!
! NDS32 Generic Port
! GNU C Compiler
!
!********************************************************************************************************
!********************************************************************************************************
! INCLUDE ASSEMBLY CONSTANTS
!********************************************************************************************************

# 1 "/opt/nds32le-elf-newlib-v3/lib/gcc/nds32le-elf/4.9.3/include/nds32_init.inc" 1 3 4







.macro nds32_init

 ! Initialize GP for data access
 la $gp, _SDA_BASE_


 ! Check HW for EX9
 mfsr $r0, $MSC_CFG
 li $r1, (1 << 24)
 and $r2, $r0, $r1
 beqz $r2, 1f

 ! Initialize the table base of EX9 instruction
 la $r0, _ITB_BASE_
 mtusr $r0, $ITB
1:
# 40 "/opt/nds32le-elf-newlib-v3/lib/gcc/nds32le-elf/4.9.3/include/nds32_init.inc" 3 4
 ! Initialize default stack pointer
 la $sp, _stack

.endm
# 15 "start.S" 2
# 1 "nds32_defs.h" 1
# 16 "start.S" 2





 .global OS_Init_Nds32
 .global OS_Int_Vectors
 .global OS_Int_Vectors_End

 .macro WEAK_DEFAULT weak_sym, default_handler
 .weak \weak_sym
 .set \weak_sym ,\default_handler
 .endm

 ! Define standard NDS32 vector table entry point of
 ! exception/interruption vectors
 .macro VECTOR handler
 WEAK_DEFAULT \handler, OS_Default_Exception
 .align 4
__\handler:




  pushm $r0, $r5
  la $r0, \handler
  jr5 $r0

 .endm

 .macro INTERRUPT_VECTOR num
 WEAK_DEFAULT OS_Trap_Interrupt_HW\num, OS_Default_Interrupt
 .align 4
__OS_Trap_Interrupt_HW\num:





  pushm $r0, $r5
  la $r1, OS_Trap_Interrupt_HW\num
  li $r0, \num
  jr5 $r1

 .endm

!********************************************************************************************************
! Vector Entry Table
!********************************************************************************************************

 .section .nds32_init, "ax"

OS_Int_Vectors:
 b OS_Init_Nds32 ! (0) Trap Reset/NMI
        b _mainCRTStartup
 VECTOR OS_Trap_TLB_Fill ! (1) Trap TLB fill
 VECTOR OS_Trap_PTE_Not_Present ! (2) Trap PTE not present
 VECTOR OS_Trap_TLB_Misc ! (3) Trap TLB misc
 VECTOR OS_Trap_TLB_VLPT_Miss ! (4) Trap TLB VLPT miss
 VECTOR OS_Trap_Machine_Error ! (5) Trap Machine error
 VECTOR OS_Trap_Debug_Related ! (6) Trap Debug related
 VECTOR OS_Trap_General_Exception ! (7) Trap General exception
 VECTOR OS_Trap_Syscall ! (8) Syscall

 ! Interrupt vectors
 .altmacro
 .set irqno, 0
 .rept 32
 INTERRUPT_VECTOR %irqno
 .set irqno, irqno+1
 .endr

 .align 4
OS_Int_Vectors_End:

!******************************************************************************************************
! Start Entry
!******************************************************************************************************
 .section .text
 .global _start
OS_Init_Nds32:
_start:
 !************************** Begin of do-not-modify **************************
 ! Please don't modify this code
 ! Initialize the registers used by the compiler

 nds32_init ! NDS32 startup initial macro in <nds32_init.inc>

 !*************************** End of do-not-modify ***************************
# 121 "start.S"
 ! Do system low level setup. It must be a leaf function.
 bal _nds32_init_mem


 ! We do this on a word basis.
 ! Currently, the default linker script guarantee
 ! the __bss_start/_end boundary word-aligned.

 ! Clear bss
 la $r0, __bss_start
 la $r1, _end
 sub $r2, $r1, $r0 ! $r2: Size of .bss
 beqz $r2, clear_end

 andi $r7, $r2, 0x1f ! $r7 = $r2 mod 32
 movi $r3, 0
 movi $r4, 0
 movi $r5, 0
 movi $r6, 0
 movi $r8, 0
 movi $r9, 0
 movi $r10, 0
 beqz $r7, clear_loop !if $r7 == 0, bss_size%32 == 0
 sub $r2, $r2, $r7

first_clear:
 swi.bi $r3, [$r0], #4 !clear each word
 addi $r7, $r7, -4
 bnez $r7, first_clear
 li $r1, 0xffffffe0
 and $r2, $r2, $r1 !check bss_size/32 == 0 or not
 beqz $r2, clear_end !if bss_size/32 == 0 , needless to clear

clear_loop:
 smw.bim $r3, [$r0], $r10 !clear each 8 words
 addi $r2, $r2, -32
 bgez $r2, clear_loop

clear_end:
# 171 "start.S"
 ! Set-up the stack pointer
 la $sp, _stack

 ! System reset handler
 bal reset

        ! Default exceptions / interrupts handler
OS_Default_Exception:
OS_Default_Interrupt:
die:
        b die

!********************************************************************************************************
! Interrupt vector Table
!********************************************************************************************************

 .data
 .align 2

 ! These tables contain the isr pointers used to deliver interrupts
 .global OS_CPU_Vector_Table
OS_CPU_Vector_Table:
 .rept 32
 .long OS_Default_Interrupt
 .endr
