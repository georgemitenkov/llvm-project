; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: integer constant must have integer type
define void @f(b8 %a) {
  %t = xor b8 %a, 1
  ret void
}
