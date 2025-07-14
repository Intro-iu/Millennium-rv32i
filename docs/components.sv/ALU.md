# ALU

> The Arithmetic Logic Unit

|ALUOp|Operation|Expression|Description|
|:---:|:---:|:---:|:---:|
|4'b0000|ADD |`Result = A + B`|加法
|4'b0001|SUB |`Result = A - B`|减法
|4'b0010|AND |`Result = A & B`|按位与
|4'b0011|OR  |`Result = A \| B`|按位或
|4'b0100|XOR |`Result = A ^ B`|按位异或
|4'b0101|SLL |`Result = A << B[4:0]`|逻辑左移
|4'b0110|SRL |`Result = A >> B[4:0]`|逻辑右移
|4'b0111|SRA |`Result = $signed(A) >>> B[4:0]`|算数右移
|4'b1000|SLT |`Result = ($signed(A) < $signed(B))`|有符号小于则置位
|4'b1001|SLTU|`Result = (A < B)`|无符号小于则置位
|4'b1111|INVALID|Invalid|无效