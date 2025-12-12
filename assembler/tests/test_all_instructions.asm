# ================================================================================
#                    COMPREHENSIVE ASSEMBLER TEST FILE
# ================================================================================
# Tests all instruction formats and edge cases
# Expected to generate valid machine code for all instructions

# ================================================================================
# FORMAT A: No Operands - NOP, HLT, SETC, RET, RTI
# ================================================================================
NOP                     ; Test NOP
SETC                    ; Test SETC

# ================================================================================
# FORMAT B: Single Register - INC, NOT, OUT, IN, PUSH, POP
# ================================================================================
INC R0                  ; INC with R0
INC R7                  ; INC with R7
NOT R1                  ; NOT with R1
NOT R6                  ; NOT with R6
IN R2                   ; IN with R2
OUT R3                  ; OUT with R3
PUSH R4                 ; PUSH with R4
POP R5                  ; POP with R5

# ================================================================================
# FORMAT C: Two Registers - MOV, SWAP
# ================================================================================
MOV R0, R1              ; MOV R0 to R1
MOV R7, R0              ; MOV R7 to R0
SWAP R2, R3             ; SWAP R2 and R3
SWAP R5, R6             ; SWAP R5 and R6

# ================================================================================
# FORMAT D: Three Registers - ADD, SUB, AND
# ================================================================================
ADD R0, R1, R2          ; ADD R1 + R2 -> R0
ADD R7, R5, R3          ; ADD R5 + R3 -> R7
SUB R1, R2, R3          ; SUB R2 - R3 -> R1
SUB R4, R5, R6          ; SUB R5 - R6 -> R4
AND R2, R3, R4          ; AND R3 & R4 -> R2
AND R0, R7, R1          ; AND R7 & R1 -> R0

# ================================================================================
# FORMAT E: Register + Immediate - LDM
# ================================================================================
LDM R0, 0               ; Load 0
LDM R1, 100             ; Load 100 decimal
LDM R2, 65535           ; Load max 16-bit unsigned
LDM R3, -1              ; Load -1 (all 1s)
LDM R4, -100            ; Load negative number
LDM R5, 0xFF            ; Load hex value 255
LDM R6, 0x1234          ; Load hex value 0x1234
LDM R7, 1               ; Load 1

# ================================================================================
# FORMAT F: Two Registers + Immediate - IADD
# ================================================================================
IADD R0, R1, 10         ; R0 = R1 + 10
IADD R2, R3, -5         ; R2 = R3 + (-5)
IADD R4, R5, 0xFF       ; R4 = R5 + 255
IADD R6, R7, 1000       ; R6 = R7 + 1000
IADD R7, R0, 0          ; R7 = R0 + 0

# ================================================================================
# FORMAT G: Load with Offset - LDD Rdst, offset(Rsrc)
# ================================================================================
LDD R0, 0(R1)           ; R0 = M[R1 + 0]
LDD R2, 100(R3)         ; R2 = M[R3 + 100]
LDD R4, -10(R5)         ; R4 = M[R5 + (-10)]
LDD R6, 0x10(R7)        ; R6 = M[R7 + 16]

# ================================================================================
# FORMAT H: Store with Offset - STD Rsrc, offset(Rsrc2)
# ================================================================================
STD R0, 0(R1)           ; M[R1 + 0] = R0
STD R2, 50(R3)          ; M[R3 + 50] = R2
STD R4, -20(R5)         ; M[R5 + (-20)] = R4
STD R6, 0x100(R7)       ; M[R7 + 256] = R6

# ================================================================================
# FORMAT J: Interrupt - INT
# ================================================================================
INT 0                   ; Software interrupt 0
INT 1                   ; Software interrupt 1

# ================================================================================
# FORMAT A: Return Instructions
# ================================================================================
RET                     ; Return from subroutine
RTI                     ; Return from interrupt

# ================================================================================
# TEST WITH LABELS - FORMAT I: Jump/Call with Address
# ================================================================================
START:
    LDM R0, 5           ; Counter = 5
    LDM R1, 0           ; Sum = 0

LOOP:
    ADD R1, R1, R0      ; Sum += Counter
    INC R0              ; Counter++
    JZ EXIT             ; If zero, exit loop
    JN NEGATIVE         ; If negative, go to NEGATIVE
    JC CARRY            ; If carry, go to CARRY
    JMP LOOP            ; Continue loop

NEGATIVE:
    NOT R1              ; Complement sum
    JMP EXIT            ; Go to exit

CARRY:
    SETC                ; Set carry flag
    JMP EXIT            ; Go to exit

EXIT:
    OUT R1              ; Output result
    CALL SUBROUTINE     ; Call subroutine
    HLT                 ; Halt

SUBROUTINE:
    PUSH R0             ; Save R0
    PUSH R1             ; Save R1
    ADD R0, R0, R1      ; Some operation
    POP R1              ; Restore R1
    POP R0              ; Restore R0
    RET                 ; Return

# ================================================================================
# END OF TEST FILE
# ================================================================================
