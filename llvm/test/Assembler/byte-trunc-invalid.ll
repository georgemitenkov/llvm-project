; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid cast opcode for cast from 'b64' to 'i32'
define i32 @trunc_from_byte(b64 %arg) {
  %res = trunc b64 %arg to i32
  ret i32 %res
}
