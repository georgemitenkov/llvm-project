; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid cast opcode for cast from 'b8' to 'i32'
define void @extend(b8 %a) {
  %t = bytecast b8 %a to i32
  ret void
}
