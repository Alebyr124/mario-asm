#####################################################################################
# Samajah Abburi
# Bitmap Project
# 	A simple implementation of the game Super Marioo Bros using bitmap display,
# and taking keyboard inouts to move Mario.  
#####################################################################################

#INITIALIZING Dimensions of screen and startinng address
.eqv WIDTH 256
.eqv HEIGHT 64
.eqv MEM 0x10008000

#Colors - declaring color parameters
.eqv RED 0x00FF0000
.eqv BLUE 0x000000FF
.eqv YELLOW 0x00FFFF00
.eqv SKIN 0x00FFCC99
.eqv BROWN 0x00994C00
.eqv BLACK 0x00000000
.eqv SKYBLUE 0x003399FF
.eqv LIGHTBROWN 0x00CC6600
.eqv PALE 0x00FFE5CC
.eqv MAGENTA 0x00CC0066
.eqv DARKBROWN 0x00663300


#Storing colors ib array
	.data
colors: 	.word RED, BROWN, SKIN, BLACK, BLUE, YELLOW
		.align 2
blacks:		.word BLACK, BLACK, BLACK, BLACK, BLACK, BLACK
		.align 2
blocks:		.word PALE, DARKBROWN, LIGHTBROWN
		.align 2
skyBlueArray:	.word SKYBLUE, SKYBLUE, SKYBLUE, SKYBLUE, SKYBLUE, SKYBLUE
		.align 2
blues:		.word BLUE, BLUE, BLUE, BLUE, BLUE, BLUE
colorsu: 	.word SKIN, BLACK, BLUE, YELLOW, RED, BROWN
skyblue:	.word SKYBLUE
mag:		.word MAGENTA

msg:		.asciiz "YESSS"



#Main Program starts here - 
	.text 
main:	
	# set up starting position for boxes
	addi 	$a0, $0, WIDTH    # a0 = X axis position = WIDTH
	#addi	$a0, $a0, 	  # for testing
	#sra 	$a0, $a0, 2
	addi 	$a1, $0, HEIGHT   # a1 = Y axis postition = HEIGHT/2 + 20 
	sra 	$a1, $a1, 1
	addi	$a1, $a1, 20
	
	
	li	$t5, 0		# set i = 0
	li	$t6, 5		# ending condition for loop
#Loop to draw first set of boxes
loopBoxes : 
	la	$a2, blocks 	# Initializing register a2 with array holding block colors
	jal	draw_box	# Calling method to draw box/block
	addi	$a0, $a0, 28	# set X position for the next box 
	addi	$t5, $t5, 1	# incrementing i
	blt	$t5, $t6, loopBoxes	# if i < 5; then jump to loopBoxes to draw next box
	
	
	
	# setting parameters for the next set of boxes and drawing the second set of boxes 
	addi	$a0, $a0, -10	# set X postion for the next set boxes
	addi	$a1, $a1, -16	# set Y position for the next set of boxes
	li	$t5, 0		# set i = 0
	li	$t6, 3		# set exit condition of loop
# CREATING 2nd set of small boxes with above mentioned parameters
loopBoxes2 : 
	la	$a2, blocks		
	jal	draw_box_small	
	addi	$a0, $a0, 28	
	addi	$t5, $t5, 1	
	blt	$t5, $t6, loopBoxes2
	
	
	# setting parameters for the next set of boxes and drawing the third set of boxes
	addi	$a0, $a0, -8	
	addi	$a1, $a1, -23	
	li	$t5, 0		
	li	$t6, 3		
# CREATING 3rd set of small boxes with above mentioned parameters
loopBoxes3 : 
	la	$a2, blocks	
	jal	draw_box_small	
	addi	$a0, $a0, 28	
	addi	$t5, $t5, 1	
	blt	$t5, $t6, loopBoxes3
	

	# setting parameters for the next set of boxes and drawing the fourth set of boxes 		
	addi	$a0, $a0, -36	
	addi	$a1, $a1, 41	
	li	$t5, 0		
	li	$t6, 9		
# CREATING 4th set of small boxes with above mentioned parameters
loopBoxes4 : 
	la	$a2, blocks	
	jal	draw_box_small
	addi	$a0, $a0, 28
	addi	$t5, $t5, 1
	blt	$t5, $t6, loopBoxes4
	
	# setting parameters for the next set of boxes and drawing the fifth set of boxes 	
	addi	$a0, $a0, -52
	addi	$a1, $a1, -30
	li	$t5, 0
	li	$t6, 4
# CREATING 5th set of small boxes with above mentioned parameters
loopBoxes5 : 
	la	$a2, blocks
	jal	draw_box_small
	addi	$a0, $a0, 28
	addi	$t5, $t5, 1
	blt	$t5, $t6, loopBoxes5
	
#Creating another box
# setting parameters for the box	
	addi	$a0, $a0, -72
	addi	$a1, $a1, 9
	la	$a2, blocks
	jal	draw_box_small
	
# Calling method for playing Music	
	jal	music
	
	# set up starting position to draw Mario
	addi 	$a0, $0, WIDTH    # a0 = X = WIDTH + 20
	addi	$a0, $a0, 20
	#sra 	$a0, $a0, 2
	addi 	$a1, $0, HEIGHT   # a1 = Y = HEIGHT
	sra 	$a1, $a1, 6
	#addi	$a1, $a1, 4

# Drawing Mario	
	la	$a2, colors	# load register a2 with arrays containing colors of Mario
	jal 	draw_head	# call function to draw Mario's head
	jal	draw_body	# cakk function draw Mario's body
	
	addi	$s2, $a0, 0	# storing the value of a0 in s2
	li	$v0, 32		# calling syscal for pausing for 400 milliseconds  
	li	$a0, 400
	syscall
	addi	$a0, $s2, 0	# restoring value of a0
	
	la	$a2, blacks	# loading a2 with array if black color
	jal	erase_mario	# call erase function
	
	# loop to bring Mario from starting position down to the block
	# calling methods to caluculate the address below tip of Mario's left and right foot
	loopDown:
		jal	calc_address_right
		addi	$t6, $v0, 0
		lw	$s3, ($t6)	
		
		jal	calc_address_left
		addi	$t7, $v0, 0
		lw	$s4, ($t7)
	
		# if either address is NOT black, then exit loop
		bne	$s4, $0, contDown	
		bne	$s3, $0, contDown
	
		addi	$a1, $a1, 2	# increment Y position
		j	loopDown
	
	# re-draw Mario in the new position
	contDown:
		addi	$a1, $a1, 1
		la	$a2, colors
		jal 	draw_head
		jal	draw_body
	
	
# Main Loop to execute Mario's movement until space is hit to exit
# This includes left, right, jump, jump left and hjump right movements	
loop:
	# check for input
	lw $t0, 0xffff0000  #t1 holds if input available
    	beq $t0, 0, loop   #If no input, keep displaying
	
	# process input
	lw 	$s1, 0xffff0004
	beq	$s1, 32, exit		# input space for exit
	beq	$s1, 119, jump 		# input w to jump
	beq	$s1, 97, left  		# input a to move left
	beq	$s1, 100, right		# input d to move right
	beq	$s1, 113, jumpLeft 	# input q to jump and move left
	beq	$s1, 101, jumpRight	# input e to jump and move right
	# invalid input, ignore
	j	loop
	
# code to jump	
jump:	
	la	$a2, blacks		# erase mario
	jal	erase_mario	
	
	li	$s5, 0		# i= 0
	li	$s6, 24		# exit condition for loop

	# a loop to find how high Mario can jump by checking for black color in the top two corners of Mario  
	loopUp:
		jal	calc_address_left_up
		addi	$t6, $v0, 0
		lw	$s3, ($t6)	
	
		jal	calc_address_right_up
		addi	$t7, $v0, 0
		lw	$s4, ($t7)
		
		# if either address is NOT black, then exit loop
		bne	$s3, $0, contUp
		bne	$s4, $0, contUp
		
		addi	$a1, $a1, -1	# move Y position up
		addi	$s5, $s5, 1	# i++
		blt	$s5, $s6, loopUp	# loop for i<24
	
	# Continue after exiting loop-up
	# Draw Mario in the new loction, Pause and then re-draw when he jumps down
	contUp:
	la	$a2, colors	# draw mario in new position
	jal 	draw_head
	jal	draw_body
	
	addi	$s2, $a0, 0	#save a0
	li	$v0, 32		# syscall to pause
	li	$a0, 400
	syscall
	addi	$a0, $s2, 0	# restore a0
	
	la	$a2, blacks	# erase mario
	jal	erase_mario	

	add	$a1, $a1, $s5	# set Y position to original position and redraw mario
	la	$a2, colors
	jal 	draw_head
	jal	draw_body
	
	j	loop

#code to jump left
jumpLeft: 
	la	$a2, blacks	# erase mario
	jal	erase_mario
	
	li	$s5, 0		# i++
	li	$s6, 24		# set exit condition
	# loop to find how high Mario can jump by checking for black color in the top two corners of Mario 
	loopUpLeft:
		jal	calc_address_left_up
		addi	$t6, $v0, 0
		lw	$s3, ($t6)	
	
		jal	calc_address_right_up
		addi	$t7, $v0, 0
		lw	$s4, ($t7)
		
		# if either address is NOT black, then exit loop
		bne	$s3, $0, contUpLeft
		bne	$s4, $0, contUpLeft
		
		addi	$a1, $a1, -1		# move Y position up
		addi	$s5, $s5, 1		# i++
		ble	$s5, $s6, loopUpLeft	# loop for i<24
		
		addi	$a1, $a1, 1
		
	contUpLeft:
	li	$s7, 2		# call calc_left to check if mario can move left
	li	$v0, 1
	jal	calc_left
	beq	$v0, $s7, skipLeft	# if v0 = 2, mario can not move left, so jump to loop	
	addi	$a0, $a0, -2		# otherwise move X postion 2 pixels left
	
	skipLeft:
	la	$a2, colors		# draw mario in new position
	jal 	draw_head_backwards
	jal	draw_body
	
	addi	$s2, $a0, 0		# save a0, syscall to pause, and restore a0
	li	$v0, 32
	li	$a0, 400
	syscall
	addi	$a0, $s2, 0
	
	la	$a2, blacks	# erase mario
	jal	erase_mario
	
	j	downLeft	

#code to jump right	
jumpRight:
	la	$a2, blacks	# erase mario
	jal	erase_mario	
	
	li	$s5, 0		# i = 0
	li	$s6, 24		# set exit condition

	# loop to find how high Mario can jump by checking for black color in the top two corners of Mario 
	loopUpRight:
		jal	calc_address_left_up
		addi	$t6, $v0, 0
		lw	$s3, ($t6)	
	
		jal	calc_address_right_up
		addi	$t7, $v0, 0
		lw	$s4, ($t7)
		
		# if either address is NOT black, then exit loop
		bne	$s3, $0, contUpRight
		bne	$s4, $0, contUpRight
		
		addi	$a1, $a1, -1		# move Y position up
		addi	$s5, $s5, 1		# i++
		blt	$s5, $s6, loopUpRight	# loop for i<24
	
	contUpRight:
	li	$s0, 2		# call calc_left to check if mario can move right
	li	$v0, 1
	jal	calc_right
	beq	$v0, $s0, skipRight	# if v0 = 2, mario can not move right, so jump to loop	
	addi	$a0, $a0, 2		# otherwise move X postion 2 pixels left
	
	skipRight:
	la	$a2, colors	# draw mario in new position
	jal 	draw_head
	jal	draw_body
	
	addi	$s2, $a0, 0	# save a0, syscall to pause, and restore a0
	li	$v0, 32
	li	$a0, 400
	syscall
	addi	$a0, $s2, 0
	
	la	$a2, blacks	# erase mario
	jal	erase_mario
	
	j	downRight

#code to move left	
left:	
	li	$s7, 2		# call calc_left to check if mario can move left
	li	$v0, 1
	jal	calc_left
	beq	$v0, $s7, loop	# if v0 = 2, mario can not move left, so jump to loop	

	la	$a2, blacks		# erase mario
	jal	erase_mario	
	
	addi	$a0, $a0, -2	#shift box to the left
	la	$a2, colors	# draw mario in new position
	jal 	draw_head_backwards
	jal	draw_body
	
	
	addi	$s2, $a0, 0	# save a0, syscall to pause, and restore a0
	li	$v0, 32			
	li	$a0, 500
	syscall	
	addi	$a0, $s2, 0	# restore address in $a0
	
	la	$a2, blacks	# erase mario
	jal	erase_mario
	
	j	downLeft

#code to move right	
right:	
	li	$s0, 2		# call calc_left to check if mario can move right
	li	$v0, 1
	jal	calc_right
	beq	$v0, $s0, loop	# if v0 = 2, mario can not move right, so jump to loop	

	la	$a2, blacks	# erase mario
	jal	erase_mario	
	addi	$a0, $a0, 2	#shift box to the right
	la	$a2, colors	# draw mario in new position
	jal 	draw_head
	jal	draw_body
	
	addi	$s2, $a0, 0	# save a0, syscall to pause, and restore a0
	li	$v0, 32
	li	$a0, 500
	syscall
	addi	$a0, $s2, 0
		
	la	$a2, blacks	# erase mario
	jal	erase_mario
		
	j	downRight
	
# code to calculate how far down mario can move while moving or jumping right	
downRight:	
	# loop to bring Mario from starting position down to the block
	# calling methods to caluculate the address below tip of Mario's left and right foot
	loopDownRight:
		jal	calc_address_right
		addi	$t6, $v0, 0
		lw	$s3, ($t6)	
		
		jal	calc_address_left
		addi	$t7, $v0, 0
		lw	$s4, ($t7)
	
		# if either address is NOT black, then exit loop
		bne	$s4, $0, contDownRight
		bne	$s3, $0, contDownRight
	
	
		#bne	$t1, $t3, contDownRight	
		addi	$a1, $a1, 2	# move Y tp next position
		j	loopDownRight
	
	contDownRight:
		la	$a2, colors	# redraw mario
		jal 	draw_head
		jal	draw_body
		j	loop	

# code to calculate how far down mario can move while moving or jumping right
downLeft:	
	# loop to bring Mario from starting position down to the block
	# calling methods to caluculate the address below tip of Mario's left and right foot
	loopDownLeft:
		jal	calc_address_right
		addi	$t6, $v0, 0
		lw	$s3, ($t6)	
		
		jal	calc_address_left
		addi	$t7, $v0, 0
		lw	$s4, ($t7)
	
		# if either address is NOT black, then exit loop
		bne	$s4, $0, contDownLeft
		bne	$s3, $0, contDownLeft
		
		addi	$a1, $a1, 2	# move Y tp next position
		j	loopDownLeft
		
		addi	$a1, $a1, 1
	
	contDownLeft:
		la	$a2, colors	#redraw mario
		jal 	draw_head_backwards
		jal	draw_body
		j	loop		


# syscall to exit program	
exit:	li	$v0, 10
	syscall


##################################################
#
#	Following METHODS are called 
#
###################################################
# Music Method - this method creates the music of Super Mario Bros
# by using syscall 31
music:

	li	$v0, 32
	li	$a0, 250
	syscall
	
	li	$v0, 31
	li	$a0, 76
	li	$a1, 100
	li	$a2, 86
	li	$a3, 50
	syscall
	
	li	$v0, 31
	li	$a0, 64
	li	$a1, 100
	li	$a2, 86
	li	$a3, 20
	syscall
	
	li	$v0, 32
	li	$a0, 200
	syscall
	
	li	$v0, 31
	li	$a0, 76
	li	$a1, 150
	li	$a2, 86
	li	$a3, 50
	syscall
	
	li	$v0, 31
	li	$a0, 64
	li	$a1, 150
	li	$a2, 86
	li	$a3, 20
	syscall

	li	$v0, 32
	li	$a0, 250
	syscall

	li	$v0, 31	
	li	$a0, 76
	li	$a1, 200
	li	$a2, 86
	li	$a3, 50
	syscall
	
	li	$v0, 31	
	li	$a0, 64
	li	$a1, 200
	li	$a2, 86
	li	$a3, 20
	syscall
	
	li	$v0, 32
	li	$a0, 250
	syscall

	li	$v0, 31	
	li	$a0, 72
	li	$a1, 150
	li	$a2, 86
	li	$a3, 50
	syscall
	
	li	$v0, 32
	li	$a0, 170
	syscall

	li	$v0, 31	
	li	$a0, 76
	li	$a1, 200
	li	$a2, 86
	li	$a3, 50
	syscall
	
	li	$v0, 32
	li	$a0, 250
	syscall

	li	$v0, 31	
	li	$a0, 79
	li	$a1, 200
	li	$a2, 86
	li	$a3, 50
	syscall
	
	li	$v0, 32
	li	$a0, 450
	syscall

	li	$v0, 31	
	li	$a0, 67
	li	$a1, 250
	li	$a2, 86
	li	$a3, 50
	syscall
	
	li	$v0, 32
	li	$a0, 1000
	syscall
	
	
	jr	$ra
	
##################################################
# Subroutine to check if Mario can move left 
# $a0 = X
# $a1 = Y
# $a2 = color
calc_left:
	# storing the initial positions in temporary register
	addi	$s5, $a0, -4	# X position
	addi	$s4, $a1, 0	# Y poistion
	
	li	$s2, 0		# setting i = 0 
	li	$s3, 16		# setting exit condition for i = 16
#	li	$v0, 1
	la	$t3, skyblue		
	lw	$t2, ($t3)

# loop to check the line on mario's left for non-black pixels		
loopCalcLeft:	
	# $t9 = address = $gp + 4*(x + y*width)
	mul	$t9, $s4, WIDTH   # y * WIDTH
	add	$t9, $t9, $s5	  # add X
	mul	$t9, $t9, 4	  # multiply by 4 to get word offset
	add	$t9, $t9, $gp	  # add to base address
	lw	$t4, ($t9)	  # getting color at calculated address
	bne	$t4, $0, trueLeft	# if color is not black, go to  trueLeft
#	sw	$t2, ($t9)
	addi	$s4, $s4, 1	  # increment Y position
	addi	$s2, $s2, 1	  # increment i
	bge	$s2, $s3, returnCalcLeft	# check if i>=15, jump to returnCalcLeft
	j	loopCalcLeft
	
trueLeft:	li	$v0, 2		# if any block is not black, set $v0 to 2
	
returnCalcLeft:	jr	$ra
		
##################################################
# Subroutine to check if Mario can move right
# $a0 = X
# $a1 = Y
# $a2 = color
calc_right:
	# storing the initial positions in temporary register
	addi	$s5, $a0, 10	# X
	addi	$s4, $a1, 0	# Y
	
	li	$s2, 0
	li	$s3, 16
#	li	$v0, 1
	la	$t3, skyblue
	lw	$t2, ($t3)

# loop to check the line on mario's right for non-black pixels	
loopCalcRight:	
	mul	$t9, $s4, WIDTH   # y * WIDTH
	add	$t9, $t9, $s5	  # add X
	mul	$t9, $t9, 4	  # multiply by 4 to get word offset
	add	$t9, $t9, $gp	  # add to base address
	lw	$t4, ($t9)	  # getting color at calculated address
	bne	$t4, $0, trueRight	# if color is not black, go to  trueRIght
#	sw`	$t2, ($t9)
	addi	$s4, $s4, 1	  # increment Y
	addi	$s2, $s2, 1	  # i++
	bge	$s2, $s3, returnCalcRight	# check if i>=15, jump to returnCalcRight
	j	loopCalcRight
	
trueRight:	li	$v0, 2		# if any block is not black, set $v0 to 2
	
returnCalcRight:	jr	$ra
		

##################################################
# subroutine to calculate the address above top right corner of mario
# $a0 = X
# $a1 = Y
# $a2 = color
calc_address_right_up:
	# storing the initial positions in temporary register
	addi	$t1, $a0, 8
	addi	$t3, $a1, -1
	
	
	mul	$v0, $t3, WIDTH   # y * WIDTH
	add	$v0, $v0, $t1	  # add X
	mul	$v0, $v0, 4	  # multiply by 4 to get word offset
	add	$v0, $v0, $gp	  # add to base address
	
	jr	$ra
		
##################################################
# subroutine to calculate the address above top left corner of mario
# $a0 = X
# $a1 = Y
# $a2 = color
calc_address_left_up:
	# storing the initial positions in temporary register
	addi	$t1, $a0, -3
	addi	$t3, $a1, -1
	
	
	mul	$v0, $t3, WIDTH   # y * WIDTH
	add	$v0, $v0, $t1	  # add X
	mul	$v0, $v0, 4	  # multiply by 4 to get word offset
	add	$v0, $v0, $gp	  # add to base address
	
	jr	$ra
		
##################################################
# subroutine to calculate the address under the tip of mario's right foot
# $a0 = X
# $a1 = Y
# $a2 = color
calc_address_right:

	addi	$t1, $a0, 8
	addi	$t3, $a1, 17
	
	# $t9 = address = $gp + 4*(x + y*width)
	mul	$v0, $t3, WIDTH   # y * WIDTH
	add	$v0, $v0, $t1	  # add X
	mul	$v0, $v0, 4	  # multiply by 4 to get word offset
	add	$v0, $v0, $gp	  # add to base address
	
	jr	$ra
		
##################################################
# subroutine to calculate the address under the tip of left mario's foot
# $a0 = X
# $a1 = Y
# $a2 = color
calc_address_left:
	# storing the initial positions in temporary register
	addi	$t1, $a0, -3
	addi	$t3, $a1, 17
	
	
	mul	$v0, $t3, WIDTH   # y * WIDTH
	add	$v0, $v0, $t1	  # add X
	mul	$v0, $v0, 4	  # multiply by 4 to get word offset
	add	$v0, $v0, $gp	  # add to base address
	
	jr	$ra
		

#################################################
# subroutine to draw a horizontal line
# $a0 = X
# $a1 = Y
# $a2 = color
# $a3 = end condition of loop
draw_line:
	li	$t0, 0		# i = 0
	lw	$t2, ($a2)	# store color at $a2 in $t2
loopline:
	# $t9 = address = $gp + 4*(x + y*width)
	mul	$t9, $a1, WIDTH   # y * WIDTH
	add	$t9, $t9, $a0	  # add X
	mul	$t9, $t9, 4	  # multiply by 4 to get word offset
	add	$t9, $t9, $gp	  # add to base address
	
	sw	$t2, ($t9)	  # store color at memory location
	addi	$a0, $a0, 1	  # increment X or width
	addi	$t0, $t0, 1	  # increment i in for loop
	blt	$t0, $a3, loopline  	# if i< value $a3, jump to loop	
	
	jr	$ra
	
	
#################################################
# subroutine to draw a vertical line
# $a0 = X
# $a1 = Y
# $a2 = color
# $a3 = end condition of loop
draw_line_vertical:
	li	$t0, 0		# i - 0
	lw	$t2, ($a2)	# store color at $a2 in $t2
loopV:
	# $t9 = address = $gp + 4*(x + y*width)
	mul	$t9, $a1, WIDTH   # y * WIDTH
	add	$t9, $t9, $a0	  # add X
	mul	$t9, $t9, 4	  # multiply by 4 to get word offset
	add	$t9, $t9, $gp	  # add to base address
	
	sw	$t2, ($t9)	  # store color at memory location
	addi	$a1, $a1, 1	  # increment X or width
	addi	$t0, $t0, 1	  # increment i in for loop
	blt	$t0, $a3, loopV	  # if i< value $a3, jump to loop	
	
	jr	$ra
	

#################################################
# subroutine to draw a pixel
# $a0 = X
# $a1 = Y
# $a2 = color
draw_pixel:	
	lw	$t2, ($a2)	# store color at $a2 in $t2

	# $t9 = address = $gp + 4*(x + y*width)
	mul	$t9, $a1, WIDTH   # y * WIDTH
	add	$t9, $t9, $a0	  # add X
	mul	$t9, $t9, 4	  # multiply by 4 to get word offset
	add	$t9, $t9, $gp	  # add to base address
	sw	$t2, ($t9)	  # store color at memory location

	jr	$ra

#################################################
# subroutine to draw a brown box
# $a0 = X
# $a1 = Y
# $a2 = color	
draw_box: 
	# $save $ra
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	li	$a3, 14		# set exit condition and draw top line
	jal	draw_line
	
	addi	$a0, $a0, -14	# set position and exit condition and draw left outline
	li	$a3, 10
	jal	draw_line_vertical
	
	li	$a3, 14		# set position and exit condition and draw bottom outline
	addi	$a2, $a2, 4
	jal	draw_line
	
	addi	$a1, $a1, -10	# set position and exit condition and draw right outline
	li	$a3, 10
	jal	draw_line_vertical
	
	## set position and exit condition to fill inside of box
	addi	$a0, $a0, -13
	addi	$a1, $a1, -9
	addi	$a2, $a2, 4
	li	$a3, 13
	
	li	$t1, 0	# i - 0
	li	$t3, 9	# exit condition of loop

# loop to fill inside of box
loopBox:	
	jal	draw_line
	addi	$a1, $a1, 1		# increment Y for next line
	addi	$t1, $t1, 1		# i++
	addi	$a0, $a0, -13		# reset X position
	blt	$t1, $t3, loopBox
	
	#reset positions of X and Y to starting positions
	addi	$a0, $a0, -14
	addi	$a1, $a1, -10
	
	#restore $ra
	lw 	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
#################################################
# subroutine to draw a smaller brown box
# $a0 = X
# $a1 = Y
# $a2 = color
draw_box_small: 
	# $save $ra
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	la	$a3, 14		# set exit condition and draw top line
	jal	draw_line
	
	li	$a3, 4		# set position and exit condition and draw left outline
	addi	$a0, $a0, -14
	jal	draw_line_vertical
	
	li	$a3, 14		# set position and exit condition and draw bottom outline
	addi	$a0, $a0, 1
	addi	$a1, $a1, -1
	addi	$a2, $a2, 4
	jal	draw_line
	
	li	$a3, 3		# set position and exit condition and draw right outline
	addi	$a0, $a0, -1
	addi	$a1, $a1, -3
	jal	draw_line_vertical
	
	## set position and exit condition to fill inside of box
	addi	$a0, $a0, -13
	addi	$a1, $a1, -2
	addi	$a2, $a2, 4
	li	$a3, 13
	
	li	$t1, 0		# i = 0
	li	$t3, 2		# set exit condition of loop

# loop to fill inside of box
loopBoxSmall:	
	jal	draw_line
	addi	$a1, $a1, 1		# increment Y for next line
	addi	$t1, $t1, 1		# i++
	addi	$a0, $a0, -13		# reset X position
	blt	$t1, $t3, loopBoxSmall
	
	#reset positions of X and Y to starting positions
	addi	$a0, $a0, -14
	addi	$a1, $a1, -3
	
	#restore $ra
	lw 	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
#################################################
# subroutine to draw mario;s head facing forward
# $a0 = X
# $a1 = Y
# $a2 = color	
draw_head : 
	# save $ra
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	li 	$a3, 5		  #draw top line of cap
	jal	draw_line
	
	
	li	$a3, 9		 # draw second line of cap
	addi	$a0, $a0, -6
	addi	$a1, $a1, 1
	jal	draw_line
		
	
	li 	$a3, 4		  # draw skin part of first line of head
	addi	$a0, $a0, -6
	addi	$a1, $a1, 1
	addi	$a2, $a2, 8
	jal	draw_line
	
	li 	$a3, 9		  # draw skin part of 2nd line of head
	addi	$a0, $a0, -7
	addi	$a1, $a1, 1	
	jal	draw_line
	
	li 	$a3, 10	
	addi	$a0, $a0, -9	   # draw skin part of 3rd line of head
	addi	$a1, $a1, 1	
	jal	draw_line
	
	li 	$a3, 4		   # draw skin part of 4th line of head
	addi	$a0, $a0, -9
	addi	$a1, $a1, 1	
	jal	draw_line
	
	li 	$a3, 4		   # draw lower line of mustache
	addi	$a2, $a2, -4
	jal	draw_line	

	addi	$a0, $a0, -3	  # Top part of Mustache
	addi	$a1, $a1, -1
	jal	draw_pixel

	li 	$a3, 6		  # draw skin part of 5th or last line of head
	addi	$a0, $a0, -5
	addi	$a1, $a1, 2	
	addi	$a2, $a2, 4
	lw	$t2, ($a2)
	jal	draw_line
	
	li 	$a3, 3		  # top line of hair
	addi	$a0, $a0, -7
	addi	$a1, $a1, -4	
	addi	$a2, $a2, -4
	lw	$t2, ($a2)
	jal	draw_line		
	
	li 	$a3, 2		  # draw eyes
	addi	$a0, $a0, 2
	addi 	$a2, $a2, 8
	jal	draw_line_vertical
	
	li 	$a3, 2		  # draw vertical line of hair in front of ears
	addi	$a0, $a0, -4
	addi	$a1, $a1, -1
	addi 	$a2, $a2, -8
	jal	draw_line_vertical
	
	li 	$a3, 2		  # draw vertical line of hair behind ears
	addi	$a0, $a0, -2
	addi	$a1, $a1, -2
	jal	draw_line_vertical

	li 	$a3, 8		  # draw first line of red shirt
	addi	$a0, $a0, 1
	addi	$a1, $a1, 2
	addi	$a2, $a2, -4
	jal	draw_line

	
	#restore $ra
	lw 	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
	
#################################################
# subroutine to draw mario's head backwards
# $a0 = X
# $a1 = Y
# $a2 = color
draw_head_backwards : 
	# save $ra
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	
	li 	$a3, 5		  #draw top line of cap
	addi	$a0, $a0, 1
	jal	draw_line
	
	
	li	$a3, 9		 # draw second line of cap
	addi	$a0, $a0, -8
	addi	$a1, $a1, 1
	jal	draw_line
		
	
	li 	$a3, 4		  # draw skin part of first line of head
	addi	$a0, $a0, -7
	addi	$a1, $a1, 1
	addi	$a2, $a2, 8
	jal	draw_line
	
	li 	$a3, 9		  # draw skin part of 2nd line of head
	addi	$a0, $a0, -6
	addi	$a1, $a1, 1	
	jal	draw_line
	
	li 	$a3, 10	
	addi	$a0, $a0, -10	   # draw skin part of 3rd line of head
	addi	$a1, $a1, 1	
	jal	draw_line
	
	li 	$a3, 4		   # draw skin part of 4th line of head
	addi	$a0, $a0, -5
	addi	$a1, $a1, 1	
	jal	draw_line
	
	li 	$a3, 4		   # draw lower line of mustache
	addi	$a0, $a0, -8
	addi	$a2, $a2, -4
	jal	draw_line	

	addi	$a0, $a0, -2	  # Top part of Mustache
	addi	$a1, $a1, -1
	jal	draw_pixel

	li 	$a3, 6		  # draw skin part of 5th or last line of head
	#addi	$a0, $a0, 1
	addi	$a1, $a1, 2	
	addi	$a2, $a2, 4
	lw	$t2, ($a2)
	jal	draw_line
	
	li 	$a3, 3		  # top line of hair
	addi	$a0, $a0, -2
	addi	$a1, $a1, -4	
	addi	$a2, $a2, -4
	lw	$t2, ($a2)
	jal	draw_line		
	
	li 	$a3, 2		  # draw eyes
	addi	$a0, $a0, -6
	addi 	$a2, $a2, 8
	jal	draw_line_vertical
	
	li 	$a3, 2		  # draw vertical line of hair behind of ears
	addi	$a0, $a0, 6
	addi	$a1, $a1, -1
	addi 	$a2, $a2, -8
	jal	draw_line_vertical
	
	li 	$a3, 2		  # draw vertical line of hair in front of ears
	addi	$a0, $a0, -2
	addi	$a1, $a1, -2
	jal	draw_line_vertical

	li 	$a3, 8		  # draw first line of red shirt
	addi	$a0, $a0, -6
	addi	$a1, $a1, 2
	addi	$a2, $a2, -4
	jal	draw_line
	
	
	lw 	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
##############################################################
# subroutine to draw mario's body
# $a0 = X
# $a1 = Y
# $a2 = color
draw_body : 
	# save $ra
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	li 	$a3, 10		  # draw 2nd line of red shirt
	addi	$a0, $a0, -9
	addi	$a1, $a1, 1
	jal	draw_line
	
	li 	$a3, 12		  # draw 3rd line of red shirt
	addi	$a0, $a0, -11
	addi	$a1, $a1, 1
	jal	draw_line
	
	li 	$a3, 12		  # draw first line of hands
	addi	$a0, $a0, -12
	addi	$a1, $a1, 1
	addi	$a2, $a2, 8
	jal	draw_line
	
	li 	$a3, 12		  # draw 2nd line of hands
	addi	$a0, $a0, -12
	addi	$a1, $a1, 1
	jal	draw_line
	
	li 	$a3, 12		  # draw 3rd line of hands
	addi	$a0, $a0, -12
	addi	$a1, $a1, 1
	jal	draw_line
	
	li 	$a3, 8		  # draw 4th of last line of red shirt
	addi	$a0, $a0, -10
	addi	$a1, $a1, -2
	addi	$a2, $a2, -8
	jal	draw_line
			
	li 	$a3, 4		  # draw first line of overalls
	addi	$a0, $a0, -6
	addi	$a1, $a1, -1
	addi	$a2, $a2, 16
	jal	draw_line
	
	li 	$a3, 3		  # draw first strap of overalls
	addi	$a0, $a0, -4
	addi	$a1, $a1, -2
	jal	draw_line_vertical
	
	li 	$a3, 3		  # draw 2nd strap of overalls
	addi	$a0, $a0, 3
	addi	$a1, $a1, -3
	jal	draw_line_vertical
	
	li 	$a3, 6		  # draw 2nd line of overalls
	addi	$a0, $a0, -4
	jal	draw_line
	
	li 	$a3, 6		  # draw 3rd line of overalls
	addi	$a0, $a0, -6
	addi	$a1, $a1, 1
	jal	draw_line
	
	li 	$a3, 8		  # draw 2nd line of overalls
	addi	$a0, $a0, -7
	addi	$a1, $a1, 1
	jal	draw_line
	
	li 	$a3, 3		  # draw last line of left pant
	addi	$a0, $a0, -8
	addi	$a1, $a1, 1
	jal	draw_line
	
	li 	$a3, 3		  # draw last line of right pant
	addi	$a0, $a0, 2
	jal	draw_line
	
	li 	$a3, 3		  # draw first line of left boot
	addi	$a0, $a0, -9
	addi	$a1, $a1, 1
	addi	$a2, $a2, -12
	jal	draw_line
	
	li 	$a3, 3		  # draw first line of right boot
	addi	$a0, $a0, 4
	jal	draw_line
	
	li 	$a3, 4		  # draw 2nd line of left boot
	addi	$a0, $a0, -11
	addi	$a1, $a1, 1
	jal	draw_line
	
	li 	$a3, 4		  # draw 2nd line of right boot
	addi	$a0, $a0, 4
	jal	draw_line
	
	addi	$a0, $a0, -5	  # draw left button of overall
	addi	$a1, $a1, -5
	addi	$a2, $a2, 16
	jal	draw_pixel	  
	
	
	addi	$a0, $a0, -3	  # draw right button of overall
	jal	draw_pixel
	
	#reset positions of X and Y to starting positions
	addi	$a0, $a0, -1
	addi	$a1, $a1, -10
	
	#restore $ra
	lw 	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra

###########################################	
#subroutine to erase mario
# $a0 = X
# $a1 = Y
# $a2 = color
	
erase_mario :  
	# save $ra
	addi	$sp, $sp, -4
	sw	$ra, ($sp)
	
	addi	$a0, $a0, -3	# set X position
	la	$a2, blacks	# set a2 to point to black
	la	$a3, 12		# set exit condition for draw line functions
	
	li	$t1, 0		# i = 0
	li	$t3, 16		# exit condition for loop
	
loopE : 	
	jal	draw_line
	addi	$a1, $a1, 1	# increment Y for next line
	addi	$t1, $t1, 1	# i++
	addi	$a0, $a0, -12	# reset X for next line
	blt	$t1, $t3, loopE		# if i < 16, jump to loop
	
	#reset positions of X and Y to starting positions
	addi	$a0, $a0, 3
	addi	$a1, $a1, -16
	
	#restore $ra
	lw 	$ra, ($sp)
	addi	$sp, $sp, 4
	jr	$ra
	
