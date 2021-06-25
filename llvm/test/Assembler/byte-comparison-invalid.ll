; RUN: not llvm-as -disable-output %s 2>&1 | FileCheck %s

; CHECK: icmp requires integer operands
define void @f(b8 %a, b8 %b) {
  %t = icmp eq b8 %a, %b
  ret void
}
