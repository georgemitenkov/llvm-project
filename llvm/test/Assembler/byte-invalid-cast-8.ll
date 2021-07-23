; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid cast opcode for cast from 'b32' to 'float'
define void @invalid_bytcast(b32 %b) {
  %t = bytecast b32 %b to float
  ret void
}
