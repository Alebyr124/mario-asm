# Useful MIPS Assembly Macros

# end program succesfully
.macro return0
	li $v0, 10
	syscall 

.end_macro

# Reads an int and set v0 to integer read
.macro readInt
	li $v0, 5
	syscall

.end_macro

# prints a given integer passed as argument
.macro printInt(%int)
	add $a0, $zero, %int
	li $v0, 1
	syscall

.end_macro

# read a string given its size and buffer adress
# Sets the string in a0 adress
.macro readString(%bufferAdress, %stringSize)
	add $a0, $zero, %bufferAdress
	add $a1, $zero, %stringSize
	li $v0, 8
	syscall

.end_macro

# prints a string given its first char adress
.macro printString(%string)
	add $a0, $zero, %string
	li $v0, 4
	syscall

.end_macro

# Pushes ra and important registers to the stack of execution
.macro push
	sw	$ra, 0($sp)
	sw	$a0, -4($sp)
	sw	$a1, -8($sp)
	sw	$a2, -12($sp)
	sw	$a3, -16($sp)
	sw	$s0, -20($sp)
	sw	$s1, -24($sp)
	sw	$s2, -28($sp)
	sw	$s3, -32($sp)
	sw	$s4, -36($sp)
	sw	$s5, -40($sp)
	sw	$s6, -44($sp)
	sw	$s7, -48($sp)
	addi	$sp, $sp, -52

.end_macro

# Restores the registers values from memory to keep their older information
.macro pop
	addi	$sp, $sp, 52
	lw	$ra, 0($sp)
	lw	$a0, -4($sp)
	lw	$a1, -8($sp)
	lw	$a2, -12($sp)
	lw	$a3, -16($sp)
	lw	$s0, -20($sp)
	lw	$s1, -24($sp)
	lw	$s2, -28($sp)
	lw	$s3, -32($sp)
	lw	$s4, -36($sp)
	lw	$s5, -40($sp)
	lw	$s6, -44($sp)
	lw	$s7, -48($sp)

.end_macro