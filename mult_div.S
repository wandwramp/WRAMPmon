# int divide(int quotient, int divisor)
.global divide
divide:
	subui	$sp, $sp, 4
	sw	$2, 0($sp)
	sw	$3, 1($sp)
	sw	$4, 2($sp)
	sw	$5, 3($sp)

	lw	$5, 4($sp)
	lw	$3, 5($sp)

	# $2 is the counter
	# $3 is the divisor
	# $5 is the quotient

	addu	$4, $0, $0	# Zero the remainder

	srli	$4, $5, 31	# Shift the remainder register
	slli	$5, $5, 1	# Left by one bit

	addui	$2, $0, 32
	
step_2:	
	subu	$4, $4, $3	# Subtract the divisor from the left part of the remainder

	slti	$1, $4, 0	# Test the remainder

	bnez	$1, step_3b
step_3a:
	srli	$1, $5, 31	# Get the high bit of $5
	
	slli	$4, $4, 1	# Shift $5 to the left by one
	or	$4, $4, $1	# shifting in the high bit of $5
	
	slli	$5, $5, 1	# Shift $5 to the left by one
	ori	$5, $5, 1	# shifting in zero
	
	j	step_4
	
step_3b:
	addu	$4, $4, $3

	srli	$1, $5, 31	# Get the high bit of $5
	
	slli	$4, $4, 1	# Shift $4 to the left by one
	or	$4, $4, $1	# shifting in the high bit of $5
	
	slli	$5, $5, 1	# Shift $5 to the left by one
step_4:	
	subui	$2, $2, 1	# Decrement the loop counter

	bnez	$2, step_2

	srli	$4, $4, 1	# Shift the left half or remainder right one bit

	addu	$1, $5, $0	# Get the result into register $1
	
	lw	$5, 3($sp)
	lw	$4, 2($sp)
	lw	$3, 1($sp)
	lw	$2, 0($sp)
	addui	$sp, $sp, 4

	jr	$ra

# int remainder(int quotient, int divisor)
.global remainder
remainder:
	subui	$sp, $sp, 4
	sw	$2, 0($sp)
	sw	$3, 1($sp)
	sw	$4, 2($sp)
	sw	$5, 3($sp)

	lw	$5, 4($sp)
	lw	$3, 5($sp)

	# $2 is the counter
	# $3 is the divisor
	# $5 is the quotient

	addu	$4, $0, $0	# Zero the remainder

	srli	$4, $5, 31	# Shift the remainder register
	slli	$5, $5, 1	# Left by one bit

	addui	$2, $0, 32
	
rem_step_2:	
	subu	$4, $4, $3	# Subtract the divisor from the left part of the remainder

	slti	$1, $4, 0	# Test the remainder

	bnez	$1, rem_step_3b
rem_step_3a:
	srli	$1, $5, 31	# Get the high bit of $5
	
	slli	$4, $4, 1	# Shift $5 to the left by one
	or	$4, $4, $1	# shifting in the high bit of $5
	
	slli	$5, $5, 1	# Shift $5 to the left by one
	ori	$5, $5, 1	# shifting in zero
	
	j	rem_step_4
	
rem_step_3b:
	addu	$4, $4, $3

	srli	$1, $5, 31	# Get the high bit of $5
	
	slli	$4, $4, 1	# Shift $4 to the left by one
	or	$4, $4, $1	# shifting in the high bit of $5
	
	slli	$5, $5, 1	# Shift $5 to the left by one
rem_step_4:	
	subui	$2, $2, 1	# Decrement the loop counter

	bnez	$2, rem_step_2

	srli	$4, $4, 1	# Shift the left half or remainder right one bit

	addu	$1, $4, $0	# Get the result into register $1
	
	lw	$5, 3($sp)
	lw	$4, 2($sp)
	lw	$3, 1($sp)
	lw	$2, 0($sp)
	addui	$sp, $sp, 4

	jr	$ra


# int multiply(int one, int two)
.global multiply
multiply:
	subui	$sp, $sp, 4
	sw	$2, 0($sp)
	sw	$3, 1($sp)
	sw	$4, 2($sp)
	sw	$5, 3($sp)

	lw	$5, 4($sp)
	lw	$3, 5($sp)

	# $2 is the counter
	# $3 is the multiplicand
	# $5 is the product

	addu	$4, $0, $0	# Zero the product

	addui	$2, $0, 32
	
mult_step_1:	
	andi	$1, $5, 1
	beqz	$1, mult_step_2

	addu	$4, $4, $3	# Step 1a

mult_step_2:	
	srli	$5, $5, 1	# Shift the product right one bit
	andi	$1, $4, 1	# Get the lower bit of $4
	slli	$1, $1, 31	# Make it an upper bit
	or	$5, $5, $1	# Shift it into the lower half ($5)

	srli	$4, $4, 1	# Shift the upper part of the product register right

	subui	$2, $2, 1	# Decrement the loop counter

	bnez	$2, mult_step_1

	addu	$1, $5, $0	# Get the result into register $1
	
	lw	$5, 3($sp)
	lw	$4, 2($sp)
	lw	$3, 1($sp)
	lw	$2, 0($sp)
	addui	$sp, $sp, 4

	jr	$ra


