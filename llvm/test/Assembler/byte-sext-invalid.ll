; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid cast opcode for cast from 'b8' to 'i32'
define i32 @sext_from_byte(b8 %arg) {
  %res = sext b8 %arg to i32
  ret i32 %res
}
