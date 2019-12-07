.data
    initialPrompt: .asciiz "Would you like to encode ('e') or decode ('d')? "
    decodeTree: .word _e _t 0; _e: .word _i _a 'e'; _t: .word _n _m 't'; _i: .word _s _u 'i'; _a: .word _r _w 'a'; _n: .word _d _k 'n'; _m: .word _g _o 'm'; _s: .word _h _v 's'; _u: .word _f 0 'u'; _r: .word _l 0 'r'; _w: .word _p _j 'w'; _d: .word _b _x 'd'; _k: .word _c _y 'k'; _g: .word _z _q 'g'; _o: .word 0 0 'o'; _h: .word 0 0 'h'; _v: .word 0 0 'v'; _f: .word 0 0 'f'; _l: .word 0 0 'l'; _p: .word 0 0 'p'; _j: .word 0 0 'j'; _b: .word 0 0 'b'; _x: .word 0 0 'x'; _c: .word 0 0 'c'; _y: .word 0 0 'y'; _z: .word 0 0 'z'; _q: .word 0 0 'q';
    encodeArray: .word _ea _eb _ec _ed _ee _ef _eg _eh _ei _ej _ek _el _em _en _eo _ep _eq _er _es _et _eu _ev _ew _ex _ey _ez; _ea: .asciiz ".-"; _eb: .asciiz "-..."; _ec: .asciiz "-.-."; _ed: .asciiz "-.."; _ee: .asciiz "."; _ef: .asciiz "..-."; _eg: .asciiz "--."; _eh: .asciiz "...."; _ei: .asciiz ".."; _ej: .asciiz ".---"; _ek: .asciiz "-.-"; _el: .asciiz ".-.."; _em: .asciiz "--"; _en: .asciiz "-."; _eo: .asciiz "---"; _ep: .asciiz ".--."; _eq: .asciiz "--.-"; _er: .asciiz ".-."; _es: .asciiz "..."; _et: .asciiz "-"; _eu: .asciiz "..-"; _ev: .asciiz "...-"; _ew: .asciiz ".--"; _ex: .asciiz "-..-"; _ey: .asciiz "-.--"; _ez: .asciiz "--..";
    decodeBuffer: .space 5
    slash: .asciiz "/"
.text

main:

    la $a0, initialPrompt
    jal printString
    jal readChar
    move $s0, $v0
    move $a0, $v0
    jal printChar
    li $a0, 10
    jal printChar
    beq $s0, 'e' startEncode
    beq $s0, 'd' startDecode
    b terminate

    startEncode:
    jal encode
    li $a0, 10
    jal printChar
    b main

    startDecode:
    jal decode
    li $a0, 10
    jal printChar
    b main

terminate:
    li $v0, 10
    syscall

# Reads input from the console one character at a time. Each time a character
# is typed, the corresponding morse code symbols are output to the console,
# followed by a space. If enter is pressed, it is echoed to the console, and
# the procedure returns. If a character cannot be encoded, it is ignored.
encode:
    addi $sp, $sp, -4
    sw $ra, 0($sp)

    encodeLoop:
    jal readChar
    beq $v0, 10, encodeRet
    move $a0, $v0
    jal encodeChar
    beqz $v0, encodeLoop
    move $a0, $v0
    jal printString
    li $a0, 32
    jal printChar
    b encodeLoop

    encodeRet:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Reads input from the console in morse code format. The input is placed in a
# buffer. When space is pressed, the buffer is zero-terminated and passed to
# decodeChar be decoded. The decoded character is printed to the console. If 
# enter is pressed, it is echoed to the console, and the procedure returns. 
# If the character cannot be decoded, it is ignored.
decode:
    addi $sp, $sp, -8
    sw $ra, 0($sp)
    sw $s0, 4($sp)

    decodeLoop:
    la $s0, decodeBuffer
    decodeReadLoop:
    jal readChar
    beq $v0, 10, decodeRet
    beq $v0, 32, decodeSpace
    sb $v0, 0($s0)
    addi $s0, $s0, 1
    b decodeReadLoop

    decodeSpace:
    sb $0, 0($s0)
    la $a0, decodeBuffer
    jal decodeChar
    move $a0, $v0
    jal printChar
    b decodeLoop

    decodeRet:
    lw $s0, 4($sp)
    lw $ra, 0($sp)
    addi $sp, $sp, 8
    jr $ra

# Reads a single character
# ret: $v0: character read
readChar:
    li $t0, 0xffff0000
    readCharLoop:
    lw $t1, 0($t0)
    beq $t1, $0, readCharLoop
    lw $v0, 4($t0)
    jr $ra

# Prints a single character
# arg: $a0: character to print
printChar: 
    li $t0, 0xffff0008
    printCharLoop:
    lw $t1, 0($t0)
    beq $t1, $0, printCharLoop
    sw $a0, 4($t0)
    jr $ra

# Prints a (zero terminated) string
# arg: $a0: address of string to print
printString:
    li $t0, 0xffff0008
    printStringCharacterLoop:
    lb $t1, 0($a0)
    beq $t1, $0, printStringRet
    printStringWaitLoop:
    lw $t2, 0($t0)
    beq $t2, $0, printStringWaitLoop
    sw $t1, 4($t0)
    addi $a0, $a0, 1
    b printStringCharacterLoop
    printStringRet:
    jr $ra

# Decodes a series of morse code symbols and returns a single character
# arg: $a0: address of a (zero terminated) string containing morse code symbols
# ret: $v0: the decoded character; 0 on error
decodeChar:
    lb $t0, 0($a0)
    beq $t0, '/', decodeReturnSpace
    la $t0, decodeTree
    decodeCharLoop:
    beq $t0, $0, decodeReturnNull
    lb $t1, 0($a0)
    addi $a0, $a0, 1
    beqz $t1, decodeReturnLetter
    beq $t1, '.', decodeDot
    beq $t1, '-', decodeDash
    b decodeReturnNull
    decodeDot:
    lw $t0, 0($t0)
    b decodeCharLoop
    decodeDash:
    lw $t0, 4($t0)
    b decodeCharLoop

    decodeReturnSpace:
    li $v0, 32
    jr $ra
    decodeReturnLetter:
    lw $v0, 8($t0)
    jr $ra
    decodeReturnNull:
    li $v0, 0
    jr $ra

# Gives the encoding of a character in morse code
# arg: $a0: the character to encode (lower case letters and space only)
# ret: $v0: the address of a string containing the morse code encode (0 on error) 
encodeChar:
    beq $a0, ' ', encodeCharRetSlash
    blt $a0, 'a', encodeCharRetError
    bgt $a0, 'z', encodeCharRetError
    addi $a0, $a0, -97
    la $t0, encodeArray
    sll $a0, $a0, 2
    add $t0, $t0, $a0
    lw $v0, 0($t0)
    jr $ra
    encodeCharRetError:
    li $v0, 0
    jr $ra
    encodeCharRetSlash:
    la $v0, slash
    jr $ra