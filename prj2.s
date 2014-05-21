!Anthony Stange
!************************************************************************!
!									 !
! general calling convention:						 !
!									 !
! (1) Register usage is as implied in the assembler names		 !
!									 !
! (2) Stack convention							 !
!									 !
!	  The stack grows towards higher addresses.  The stack pointer	 !
!	  ($sp) points to the next available (empty) location.		 !
!									 !
! (3) Mechanics								 !
!									 !
!	  (3a) Caller at call time:					 !
!	       o  Write any caller-saved stuff not saved at entry to	 !
!		  space on the stack that was reserved at entry time.	 !
!	       o  Do a JALR leaving the return address in $ra		 !
!									 !
!	  (3b) Callee at entry time:					 !
!	       o  Reserve all stack space that the subroutine will need	 !
!		  by adding that number of words to the stack pointer,	 !
!		  $sp.							 !
!	       o  Write any callee-saved stuff ($ra) to reserved space	 !
!		  on the stack.						 !
!	       o  Write any caller-saved stuff if it makes sense to	 !
!		  do so now.						 !
!									 !
!	  (3c) Callee at exit time:					 !
!	       o  Read back any callee-saved stuff from the stack ($ra)	 !
!	       o  Deallocate stack space by subtract the number of words !
!		  used from the stack pointer, $sp			 !
!	       o  return by executing $jalr $ra, $zero.			 !
!									 !
!	  (3d) Caller after return:					 !
!	       o  Read back any caller-saved stuff needed.		 !
!									 !
!************************************************************************!

!vector table
 vector0: .fill 0x00000000 !0
 .fill 0x00000000 !1
 .fill 0x00000000 !2
 .fill 0x00000000
 .fill 0x00000000 !4
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000 !8
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000
 .fill 0x00000000 !15
!end vector table


main:
	lw $sp, initsp($sp)		! initialize the stack pointer
	addi $a0, $zero, ti_inthandler	
	sw $a0, 1($zero)		!put address of int handler on table
	ei 				!Don't forget to enable interrupts...

	addi $a0, $zero, 2	!load base for pow
	addi $a1, $zero, 6	!load power for pow
	addi $at, $zero, POW			!load address of pow
	jalr $at, $ra		!run pow
	sw $v0, answer($zero)

	halt	
answer: .fill 0x0
		

POW: 
  addi $sp, $sp, 2   ! push 2 slots onto the stack
  sw $ra, -1($sp)   ! save RA to stack
  sw $a0, -2($sp)   ! save arg 0 to stack
  beq $zero, $a1, RET1 ! if the power is 0 return 1
  beq $zero, $a0, RET0 ! if the base is 0 return 0
  addi $a1, $a1, -1  ! decrement the power
  la $at, POW	! load the address of POW
  jalr $at, $ra   ! recursively call POW
  add $a1, $v0, $zero  ! store return value in arg 1
  lw $a0, -2($sp)   ! load the base into arg 0
  la $at, MULT		! load the address of MULT
  jalr $at, $ra   ! multiply arg 0 (base) and arg 1 (running product)
  lw $ra, -1($sp)   ! load RA from the stack
  addi $sp, $sp, -2  ! pop the RA and arg 0 off the stack
  jalr $ra, $zero   ! return
RET1: addi $v0, $zero, 1  ! return a value of 1
  addi $sp, $sp, -2
  jalr $ra, $zero
RET0: add $v0, $zero, $zero ! return a value of 0
  addi $sp, $sp, -2
  jalr $ra, $zero		
	
MULT: add $v0, $zero, $zero ! zero out return value
AGAIN: add $v0,$v0, $a0  ! multiply loop
  addi $a1, $a1, -1
  beq $a1, $zero, DONE ! finished multiplying
  beq $zero, $zero, AGAIN ! loop again
DONE: jalr $ra, $zero	
		
		
ti_inthandler:
	addi $sp, $sp, 4	!increment stack pointer
	sw $k0, -4($sp)		!push k0 to stack
	ei
	sw $a0, -3($sp)		!put state of program on stack
	sw $a1, -2($sp)
	sw $a2, -1($sp)
	lw $a0, seconds($zero)	!load address of seconds into a0
	lw $a1, 0($a0)		!load value of seconds into a1
	bonj $a1, $a1		!increment seconds by one
	addi $a2, $zero, 60	!put 60 into a2
	beq $a1, $a2, minute	!jump to minutes handler if seconds == 60
	sw $a1, 0($a0)		!!= null push seconds to memory
	beq $zero, $zero, END	!finish handler
minute:
	add $a1 , $zero, $zero	!clear seconds
	sw $a1, 0($a0)		!push 0 seconds into memory
	lw $a0, minutes($zero)	!load address of minutes into a0
	lw $a1, 0($a0)		!load value of minutes into a1
	bonj $a1, $a1		!increment minutes
	beq $a1, $a2, hour	!check if minutes == 60
	sw $a1, 0($a0)		!!= save minutes to memory
	beq $zero, $zero, END 	!then finish
hour:	
	add $a1, $zero, $zero 	!clear minutes
	sw $a1, 0($a0)		!push 0 minutes into memory
	lw $a0, hours($zero)	!load address of hours into a0
	lw $a1, 0($a0)		!load value of hours into $a1
	bonj $a1, $a1		!increment hours
	sw $a1, 0($a0)		!push hours into memory
END:	
	lw $a2, -1($sp)
	lw $a1, -2($sp)
	lw $a0, -3($sp)
	di
	lw $k0, -4($sp)
	addi $sp, $sp, -4
	reti	
initsp: .fill 0xA00000
seconds: .fill 0xF00000
minutes: .fill 0xF00001
hours: .fill 0xF00002
