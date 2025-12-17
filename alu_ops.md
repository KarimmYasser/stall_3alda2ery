
NOP => 0xxxxx
HLT => 0xxxxx
SETC => 1110xx
NOT => 1101xx -> send R[rs1] same as rdst because rdst doesnt enter the alu
INC => 1100xx -> send R[rs1] same as rdst because rdst doesnt enter the alu
OUT => xxxxxxx
IN => xxxxxxx
MOV => 1111xx -> (pass operand 1) OR 100100 -> (set rs2 to 0 and select R[rs2] and add it) 
SWAP => 111100 in the two cycles and enable swap_signal in the 2nd cycle
ADD => 100100
SUB => 101000
AND => 101100
IADD => 1001(01) -> ensure that the bits in the bracket are imm selection, if changed tell me
PUSH => we need to discuss either pass it through the alu or the mem take it from R[rs2]
POP => i think not related to me
LDM => 1001(01) -> send R[rs1] with 0 and select immediate and add them because we dont have pass operand 2 xxxxxxxxxxxxxx
LDD => 1001(01) -> select imm and add to R[rs1] xxxxxxxxxxxxxxxxxxx
STD => 1001(01) -> select imm and add to R[rs1] -> the difference is in the control signals xxxxxxxxxxxxxxxxxxx
JZ => 0xxxxx / ccr_enable = x / branch_opcode  = 0011
JN => 0xxxxx / ccr_enable = x / branch_opcode  = 0111
JC => 0xxxxx / ccr_enable = x / branch_opcode  = 1011
JMP => to be discussed if related to me
CALL => to be discussed if related to me
RET => to be discussed if related to me
INT => to be discussed if related to me
RTI => to be discussed if related to me
