; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid cast opcode for cast from 'b8' to 'i8'
define void @invalid_bitcast(b8 %b) {
  %t = bitcast b8 %b to i8
  ret void
}
