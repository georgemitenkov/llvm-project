; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid cast opcode for cast from 'i8' to 'b8'
define void @from_int(i8 %a) {
  %t = bytecast i8 %a to b8
  ret void
}
