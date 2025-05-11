.data
# Dictionary
dictionary: .asciiz "APPLE*BANANA*ORANGE*GRAPE*LEMON*"

# Game variables
testWord:       .space  32
guessedString:  .space 64  # Stores the display version with spaces
displayBuffer:  .space 2048
charInput:      .space 8
charInputHistory: .space 32

# Messages
welcomeMsg:     .asciiz "Welcome to Hangman!\nGuess the word to win!"
wordDisplayMsg: .asciiz "\nCurrent word: "
errorPrompt:    .asciiz "\nWrong guesses: "
inputPrompt:    .asciiz "\nGuess a letter: "
winMsg:         .asciiz "\nYou won! The word was: "
loseMsg:        .asciiz "\nYou lost! The word was: "

# Hangman states
hangmanStates:  .word hang0, hang1, hang2, hang3, hang4, hang5, hang6, hang7
hang0: .asciiz "  +---+\n  |   |\n      |\n      |\n      |\n      |\n========="
hang1: .asciiz "  +---+\n  |   |\n  O   |\n      |\n      |\n      |\n========="
hang2: .asciiz "  +---+\n  |   |\n  O   |\n  |   |\n      |\n      |\n========="
hang3: .asciiz "  +---+\n  |   |\n  O   |\n /|   |\n      |\n      |\n========="
hang4: .asciiz "  +---+\n  |   |\n  O   |\n /|\\  |\n      |\n      |\n========="
hang5: .asciiz "  +---+\n  |   |\n  O   |\n /|\\  |\n /    |\n      |\n========="
hang6: .asciiz "  +---+\n  |   |\n  O   |\n /|\\  |\n / \\  |\n      |\n========="
hang7: .asciiz "  +---+\n  |   |\n  O   |\n /|\\  |\n / \\  |\n      |\n=========\nGame Over!"

.text
.globl main

main:
    # Show welcome
    li $v0, 55
    la $a0, welcomeMsg
    li $a1, 1
    syscall
    
    # Select random word
    jal selectWord
    
    # Initialize guessed string with underscores
    la $a0, testWord
    jal strlen
    move $s0, $v0  # Store word length
    
    la $a0, guessedString
    la $a1, testWord
    jal initGuessed
    
    li $s1, 0      # Error count

gameLoop:
    # Clear display buffer
    la $a0, displayBuffer
    li $t0, 0
clearBuffer:
    sb $zero, 0($a0)
    addi $a0, $a0, 1
    addi $t0, $t0, 1
    blt $t0, 2048, clearBuffer
    
    # Build display - start with hangman
    la $a0, displayBuffer
    move $a1, $s1
    jal drawHangman
    
    # Add word display
    la $a0, displayBuffer
    jal strlen
    add $a0, $a0, $v0
    la $a1, wordDisplayMsg
    jal strcat
    
    # Add guessed word with spaces
    la $a0, displayBuffer
    jal strlen
    add $a0, $a0, $v0
    la $a1, guessedString
    jal strcat
    
    # Add errors
    la $a0, displayBuffer
    jal strlen
    add $a0, $a0, $v0
    la $a1, errorPrompt
    jal strcat
    
    # Add error count
    la $a0, displayBuffer
    jal strlen
    add $a0, $a0, $v0
    addi $t0, $s1, '0'
    sb $t0, 0($a0)
    addi $a0, $a0, 1
    sb $zero, 0($a0)
    
    # Add input prompt
    la $a0, displayBuffer
    jal strlen
    add $a0, $a0, $v0
    la $a1, inputPrompt
    jal strcat
    
    # Show dialog
    li $v0, 54
    la $a0, displayBuffer
    la $a1, charInput
    li $a2, 8
    syscall
    
    # Check for cancel
    beq $a1, -2, exit
    
    # Get input
    la $t0, charInput
    lb $s2, 0($t0)
    beqz $s2, gameLoop
    
    # Check if already guessed
    la $a0, charInputHistory
    move $a1, $s2
    jal contains
    bnez $v0, gameLoop
    
    # Add to history
    la $a0, charInputHistory
    move $a1, $s2
    jal append
    
    # Check if in word
    la $a0, testWord
    move $a1, $s2
    jal find
    move $s3, $v0
    
    beqz $s3, wrong
    
    # Update display with correct letter
    la $a0, guessedString
    la $a1, testWord
    move $a2, $s2
    jal update
    
    # Check if won
    la $a0, guessedString
    jal countBlanks
    beqz $v0, win
    
    j gameLoop
    
wrong:
    addi $s1, $s1, 1
    beq $s1, 7, lose
    j gameLoop

win:
    li $v0, 55
    la $a0, winMsg
    la $a1, testWord
    li $a2, 0
    syscall
    j exit

lose:
    li $v0, 55
    la $a0, loseMsg
    la $a1, testWord
    li $a2, 0
    syscall

exit:
    li $v0, 10
    syscall

# ===== UTILITY FUNCTIONS =====

selectWord:
    # Count words
    la $t0, dictionary
    li $t1, 0
    
count:
    lb $t2, 0($t0)
    beqz $t2, doneCount
    addi $t0, $t0, 1
    bne $t2, '*', count
    addi $t1, $t1, 1
    j count
    
doneCount:
    # Random index
    move $a1, $t1
    li $v0, 42
    syscall
    
    # Find word
    la $t0, dictionary
    li $t1, 0
    
findWord:
    beq $t1, $a0, found
    lb $t2, 0($t0)
    beqz $t2, found
    addi $t0, $t0, 1
    bne $t2, '*', findWord
    addi $t1, $t1, 1
    j findWord
    
found:
    # Copy word
    la $t1, testWord
    
copy:
    lb $t2, 0($t0)
    beqz $t2, doneCopy
    beq $t2, '*', doneCopy
    sb $t2, 0($t1)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j copy
    
doneCopy:
    sb $zero, 0($t1)
    jr $ra

initGuessed:
    move $t0, $a0
    move $t1, $a1
    
initLoop:
    lb $t2, 0($t1)
    beqz $t2, doneInit
    li $t3, '_'
    sb $t3, 0($t0)
    addi $t0, $t0, 1
    li $t3, ' '
    sb $t3, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j initLoop
    
doneInit:
    sb $zero, 0($t0)
    jr $ra

drawHangman:
    la $t0, hangmanStates
    sll $t1, $a1, 2
    add $t0, $t0, $t1
    lw $a1, 0($t0)
    j strcpy

find:
    li $v0, 0
    move $t0, $a0
    
findLoop:
    lb $t1, 0($t0)
    beqz $t1, doneFind
    bne $t1, $a1, noMatch
    addi $v0, $v0, 1
noMatch:
    addi $t0, $t0, 1
    j findLoop
    
doneFind:
    jr $ra

update:
    move $t0, $a0
    move $t1, $a1
    li $t3, 0
    
updateLoop:
    lb $t2, 0($t1)
    beqz $t2, doneUpdate
    bne $t2, $a2, nextPos
    
    # Calculate position in guessedString (2 bytes per char)
    sll $t4, $t3, 1
    add $t5, $t0, $t4
    sb $a2, 0($t5)  # Store the correct letter
    
nextPos:
    addi $t1, $t1, 1
    addi $t3, $t3, 1
    j updateLoop
    
doneUpdate:
    jr $ra

countBlanks:
    li $v0, 0
    move $t0, $a0
    
blankLoop:
    lb $t1, 0($t0)
    beqz $t1, doneBlank
    li $t2, '_'
    bne $t1, $t2, notBlank
    addi $v0, $v0, 1
notBlank:
    addi $t0, $t0, 2  # Skip space
    j blankLoop
    
doneBlank:
    jr $ra

contains:
    move $t0, $a0
    
containsLoop:
    lb $t1, 0($t0)
    beqz $t1, notContain
    beq $t1, $a1, doesContain
    addi $t0, $t0, 1
    j containsLoop
    
doesContain:
    li $v0, 1
    jr $ra
    
notContain:
    li $v0, 0
    jr $ra

append:
    move $t0, $a0
    
appendLoop:
    lb $t1, 0($t0)
    beqz $t1, doAppend
    addi $t0, $t0, 1
    j appendLoop
    
doAppend:
    sb $a1, 0($t0)
    addi $t0, $t0, 1
    sb $zero, 0($t0)
    jr $ra

strcpy:
    move $t0, $a0
    move $t1, $a1
    
cpyLoop:
    lb $t2, 0($t1)
    beqz $t2, doneCpy
    sb $t2, 0($t0)
    addi $t0, $t0, 1
    addi $t1, $t1, 1
    j cpyLoop
    
doneCpy:
    sb $zero, 0($t0)
    jr $ra

strcat:
    move $t0, $a0
    
catLoop1:
    lb $t1, 0($t0)
    beqz $t1, doCat
    addi $t0, $t0, 1
    j catLoop1
    
doCat:
    move $a0, $t0
    j strcpy

strlen:
    li $v0, 0
    move $t0, $a0
    
lenLoop:
    lb $t1, 0($t0)
    beqz $t1, doneLen
    addi $v0, $v0, 1
    addi $t0, $t0, 1
    j lenLoop
    
doneLen:
    jr $ra