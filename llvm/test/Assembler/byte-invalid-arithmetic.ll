; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: invalid operand type for instruction
define void @f(b8 %a, b8 %b) {
  %t = add b8 %a, %b
  ret void
}
