push r3                ;x[sp] <= R[r2]
pop  r5
nop
label:
setc
not r7
add r4, r3, r5
inc r6
out r6  ## forward outdata
in r1
mov r1, r4
swap r4, r1
sub r2, r5, r6
iadd r1, r2, 10
ldm r4, 100
;
LDD R2, 100(R3)
jmp  5
add r2, r5, r7
hlt