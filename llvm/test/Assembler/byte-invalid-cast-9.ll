; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid cast opcode for cast from 'i8' to 'b8'
define void @invalid_bytcast(i8 %b) {
  %t = bytecast i8 %b to b8
  ret void
}
