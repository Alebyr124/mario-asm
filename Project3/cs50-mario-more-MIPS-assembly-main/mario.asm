# CS50's pset1 Mario's Pyramid in MIPS Assembly
.include "macros.asm"

.data
	height: .asciiz "Height: "
	space: 	.asciiz " " 	# defines a space = 2 for the gap between two pyramids
	newline: .asciiz "\n"
	brick: .asciiz "#"

.text
	li	$s0, 0		# sets s1 to 0, so I can initialize the DO-WHILE without problems
				# s1 will be where my readen heigth will live
	la	$s1, height

DO_WHILE: 
	sgt	$t0, $s0, 0	# If s0 > 1, t0 = 1
	slti	$t1, $s0, 9	# If s0 < 9, t1 = 1
	and	$t2, $t0, $t1	# t2 = t0 && t1
	beq	$t2, 1, EXIT	# If s0 > 0 && s0 < 9, EXIT the DO_WHILE
	
	printString($s1)
	readInt
	add 	$s0, $zero, $v0	# Saves the return of readInt in a safe register
	
	j DO_WHILE		# Keeps the user inside the loop until he types height > 0

EXIT: 
	add	$a0, $zero, $s0	# Loads the user input into a0 to use in the function printPyramid
	jal printPyramid
	return0
	
printPyramid:
	# a0 gets the height of the pyramid to be printed
	push
	
	add	$s0, $zero, $a0
	addi	$s0, $s0, 1	# s0 saves height + 1, because its what I need in the For loop
	li	$s1, 1		# s1 = 1

FORpyrmd:
	slt	$t0, $s1, $s0
	beq	$t0, 0, EXITpyrmd
	
	# prints height - n spaces
	la	$a0, space
	sub	$a1, $s0, $s1	# a1 = s0 - s1 --> a1 = height + 1 - i
	jal printRepeatedly
	
	# prints n bricks
	la	$a0, brick
	add	$a1, $zero, $s1	# a1 = i
	jal printRepeatedly
	
	# prints 2 spaces between 2 bricks
	la	$a0, space
	addi	$a1, $zero, 2
	jal printRepeatedly
	
	# prints n bricks
	la	$a0, brick
	add	$a1, $zero, $s1
	jal printRepeatedly
	
	# prints a new line
	la	$a0, newline
	addi	$a1, $zero, 1
	jal printRepeatedly
	
	addi	$s1, $s1, 1
	j FORpyrmd
	
EXITpyrmd:
	pop
	jr $ra

printRepeatedly:
	# a0 has the char to be printed
	# a1 has the number of times to be printed
	push
	
	li	$s0, 0		# initializes s0 with 0
	
FORrep:
	slt	$t1, $s0, $a1
	beq	$t1, 0, EXITrep	# Keep in the loop as long as s0 < a1
	
	printString($a0)
	
	addi	$s0, $s0, 1	# i++
	j FORrep

EXITrep:	
	pop
	
	jr $ra
	
