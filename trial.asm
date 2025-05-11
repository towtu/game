.data
bitmap_base:   .word 0x10040000
word:          .asciiz "MARS"
underscore:    .asciiz "_ _ _ _"
input_prompt:  .asciiz "\nEnter a letter: "
correct_msg:   .asciiz "Correct!\n"
wrong_msg:     .asciiz "Wrong!\n"
win_msg:       .asciiz "\nYou win!\n"
lose_msg:      .asciiz "\nYou lose!\n"
used_letters:  .space 26
guess_count:   .word 0
max_wrong:     .word 6

.text
.globl main

main:
    li $t0, 0                  # Wrong guesses
    li $t1, 0                  # Correct letters
    la $a0, underscore
    li $v0, 4
    syscall                   # Print underscores

game_loop:
    la $a0, input_prompt
    li $v0, 4
    syscall

    li $v0, 12                # Read character
    syscall
    move $t2, $v0             # Store input in $t2

    # Check if the guess is correct
    li $t3, 0                 # Correct guess flag
    la $t4, word
    li $t5, 0

check_loop:
    lb $t6, 0($t4)
    beqz $t6, check_end
    beq $t6, $t2, correct_guess
    addiu $t4, $t4, 1
    addiu $t5, $t5, 1
    j check_loop

correct_guess:
    li $t3, 1                 # Set correct flag
    addiu $t1, $t1, 1         # Increment correct guess count

check_end:
    beq $t3, 1, show_correct

    # Wrong guess
    addiu $t0, $t0, 1
    la $a0, wrong_msg
    li $v0, 4
    syscall
    jal draw_hangman
    b check_lose

show_correct:
    la $a0, correct_msg
    li $v0, 4
    syscall

check_lose:
    lw $t7, max_wrong
    bge $t0, $t7, lose

    li $t8, 4                 # Word length
    beq $t1, $t8, win

    j game_loop

win:
    la $a0, win_msg
    li $v0, 4
    syscall
    j end

lose:
    la $a0, lose_msg
    li $v0, 4
    syscall
    j end

end:
    li $v0, 10
    syscall

# === Draw Hangman Stick Figure Based on $t0 (wrong guesses) ===
draw_hangman:
    li $t9, 0x10040000        # Bitmap base

    li $t1, 1
    beq $t0, $t1, draw_head

    li $t1, 2
    beq $t0, $t1, draw_body

    li $t1, 3
    beq $t0, $t1, draw_left_arm

    li $t1, 4
    beq $t0, $t1, draw_right_arm

    li $t1, 5
    beq $t0, $t1, draw_left_leg

    li $t1, 6
    beq $t0, $t1, draw_right_leg

    jr $ra

draw_head:
    li $t2, 0xFF0000          # Red pixel
    li $t3, 20                # x
    li $t4, 5                 # y
    jal draw_pixel
    jr $ra

draw_body:
    li $t2, 0x0000FF
    li $t3, 20
    li $t4, 6
    jal draw_pixel
    jr $ra

draw_left_arm:
    li $t2, 0x00FF00
    li $t3, 19
    li $t4, 6
    jal draw_pixel
    jr $ra

draw_right_arm:
    li $t2, 0x00FF00
    li $t3, 21
    li $t4, 6
    jal draw_pixel
    jr $ra

draw_left_leg:
    li $t2, 0xFFFF00
    li $t3, 19
    li $t4, 7
    jal draw_pixel
    jr $ra

draw_right_leg:
    li $t2, 0xFFFF00
    li $t3, 21
    li $t4, 7
    jal draw_pixel
    jr $ra

# === Draw pixel at (x=$t3, y=$t4) with color $t2 ===
draw_pixel:
    li $t5, 128               # Width
    mul $t6, $t4, $t5
    add $t6, $t6, $t3         # pixel = y * width + x
    sll $t6, $t6, 2           # Word address
    li $t7, 0x10040000
    add $t7, $t7, $t6
    sw $t2, 0($t7)
    jr $ra
