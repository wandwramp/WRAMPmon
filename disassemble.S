# void disassemble(unsigned int address, unsigned int insn)
# This displays the disassembly of an instruction to the screen	
.text
.global disassemble
disassemble:	
	subui	$sp, $sp, 17
	sw	$2, 4($sp)
	sw	$3, 5($sp)
	sw	$4, 6($sp)
	sw	$5, 7($sp)
	sw	$6, 8($sp)
	sw	$7, 9($sp)
	sw	$8, 10($sp)
	sw	$9, 11($sp)
	sw	$10, 12($sp)
	sw	$11, 13($sp)
	sw	$12, 14($sp)
	sw	$13, 15($sp)
	sw	$ra, 16($sp)
	
	lw	$12, 17($sp)	# Get the parameter
	
	lw	$13, 18($sp)	# Get the actual instruction

	# OPCode = $8
	# func = $5
	# Rd = $7
	# Rs = $6
	# Rt = $2
	# immediate = $3
	# signed_immediate $9
	# address = $4
	# signed_address $10

	andi	$2, $13, 0xf	# Get the value of Rt
	andi	$3, $13, 0xffff	# Get the value of the immediate
	la	$1, 0xfffff	# Get the mask for extracting the address
	and	$4, $13, $1	# Get the value of the address
	srli	$13, $13, 16
	andi	$5, $13, 0xf
	srli	$13, $13, 4
	andi	$6, $13, 0xf
	srli	$13, $13, 4
	andi	$7, $13, 0xf
	srli	$13, $13, 4
	andi	$8, $13, 0xf

	# Get the address of the start of the table
	la	$13, insn_table
disassemble_find_insn:
	# Get the mnemonic
	lw	$1, 0($13)
	# NULL mnemonic means end of table
	beqz	$1, disassemble_end_of_table

	# Get the OPcode
	lw	$1, 2($13)
	seq	$1, $1, $8
	beqz	$1, disassemble_next_insn
	
	# Test the function field
	lw	$1, 3($13)
	seq	$1, $1, $5
	# Test the type field
	lw	$10, 4($13)
	seqi	$10, $10, 3
	or	$1, $1, $10
	bnez	$1, disassemble_end_of_table
	
disassemble_next_insn:
	# Increment the pointer
	addui	$13, $13, 5
	j	disassemble_find_insn
disassemble_end_of_table:	

	lw	$1, 0($13)
	beqz	$1, disassemble_unknown_insn

.data
mnemonic_str:
	.asciiz	"%s\t"
unknown_str:
	.asciiz "???"
.text
	la	$10, mnemonic_str
	sw	$10, 0($sp)

	sw	$1, 1($sp)
	jal	printf


	# Now we do the operands
	# Get the address of the operand format string
	lw	$10, 1($13)
	
disassemble_next_operand:	
	# Get the operand format character
	lw	$5, 0($10)
	addui	$10, $10, 1
	beqz	$5, disassemble_return
	
	seqi	$1, $5, 'd'
	beqz	$1, disassemble_special_reg_d

	la	$1, GPR_name
	addu	$1, $1, $7
	lw	$1, 0($1)
	sw	$1, 0($sp)
	jal	printf
	j	disassemble_next_operand
disassemble_special_reg_d:
	seqi	$1, $5, 'D'
	beqz	$1, disassemble_reg_s

	la	$1, SPR_name
	addu	$1, $1, $7
	lw	$1, 0($1)
	sw	$1, 0($sp)
	jal	printf
	j	disassemble_next_operand

disassemble_reg_s:
	seqi	$1, $5, 's'
	beqz	$1, disassemble_special_reg_s

	la	$1, GPR_name
	addu	$1, $1, $6
	lw	$1, 0($1)
	sw	$1, 0($sp)
	jal	printf
	j	disassemble_next_operand
disassemble_special_reg_s:	
	seqi	$1, $5, 'S'
	beqz	$1, disassemble_reg_t

	la	$1, SPR_name
	addu	$1, $1, $6
	lw	$1, 0($1)
	sw	$1, 0($sp)
	jal	printf
	j	disassemble_next_operand

disassemble_reg_t:
	seqi	$1, $5, 't'
	beqz	$1, disassemble_offset

	la	$1, GPR_name
	addu	$1, $1, $2
	lw	$1, 0($1)
	sw	$1, 0($sp)
	jal	printf
	j	disassemble_next_operand

disassemble_offset:
	seqi	$1, $5, 'o'
	beqz	$1, disassemble_branch

	# if address = 0
	bnez	$4, disassemble_non_zero_ofs

.data
zero_str:
	.asciiz	"0"
number_str:
	.asciiz	"%d"
address_str:
	.asciiz	"0x%05x"
.text
	la	$1, zero_str
	sw	$1, 0($sp)
	jal	printf
	
	j	disassemble_next_operand
disassemble_non_zero_ofs:	
	# If Rs == 0
	beqz	$6, disassemble_address
	
	la	$1, number_str
	sw	$1, 0($sp)

	# Here we must sign extend the address
	slli	$1, $4, 12
	srai	$1, $1, 12
	sw	$1, 1($sp)
	
	jal	printf
	
	j	disassemble_next_operand

disassemble_address:	
	la	$1, address_str
	sw	$1, 0($sp)
	sw	$4, 1($sp)
	jal	printf

	j	disassemble_next_operand
	
disassemble_branch:
	seqi	$1, $5, 'b'
	beqz	$1, disassemble_immediate
	
	la	$1, address_str
	sw	$1, 0($sp)

	# Sign extend the address
	slli	$8, $4, 12
	srai	$8, $8, 12
	# Add the PC
	addu	$8, $8, $12
	# Add 1
	addui	$8, $8, 1
	# And with 0xfffff
	la	$1, 0xfffff
	and	$8, $8, $1
	sw	$8, 1($sp)
	jal	printf

	j	disassemble_next_operand

disassemble_immediate:
	seqi	$1, $5, 'i'
	beqz	$1, disassemble_jump

.data
immed_str:
	.asciiz	"0x%04x"
.text

	# Needs fixing (to allow for sign extension)	
	la	$1, immed_str
	sw	$1, 0($sp)

	sw	$3, 1($sp)
	jal	printf

	j	disassemble_next_operand

disassemble_jump:
	seqi	$1, $5, 'j'
	beqz	$1, disassemble_default
	
	# Needs fixing (to allow for sign extension)	
	la	$1, address_str
	sw	$1, 0($sp)

	sw	$4, 1($sp)
	jal	printf

	j	disassemble_next_operand


disassemble_default:	
.data
char_str:	
	.asciiz "%c"
.text
	la	$1, char_str
	sw	$1, 0($sp)
	sw	$5, 1($sp)
	jal	printf
		
	j	disassemble_next_operand

disassemble_unknown_insn:	
	la	$1, unknown_str
	sw	$1, 0($sp)
	jal	printf

	j	disassemble_return
	

disassemble_return:

	lw	$2, 4($sp)
	lw	$3, 5($sp)
	lw	$4, 6($sp)
	lw	$5, 7($sp)
	lw	$6, 8($sp)
	lw	$7, 9($sp)
	lw	$8, 10($sp)
	lw	$9, 11($sp)
	lw	$10, 12($sp)
	lw	$11, 13($sp)
	lw	$12, 14($sp)
	lw	$13, 15($sp)
	lw	$ra, 16($sp)
	addui	$sp, $sp, 17

	jr	$ra	

