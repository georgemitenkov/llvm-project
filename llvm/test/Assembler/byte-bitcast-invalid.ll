; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid cast opcode for cast from 'b64' to 'i64'
define void @bitcast_from_byte_to_other_type(b64 %arg) {
  %res = bitcast b64 %arg to i64
  ret void
}
