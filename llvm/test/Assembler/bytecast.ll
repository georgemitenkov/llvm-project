; RUN: llvm-as < %s | llvm-dis | llvm-as | llvm-dis | FileCheck %s
; RUN: verify-uselistorder %s

; CHECK-LABEL: same_size1
;       CHECK: bytecast b8 %{{.*}} to i8
define void @same_size1(b8 %a) {
  %t = bytecast b8 %a to i8
  ret void
}

; CHECK-LABEL: same_size2
;       CHECK: bytecast b8 %{{.*}} to <8 x i1>
define void @same_size2(b8 %a) {
  %t = bytecast b8 %a to <8 x i1>
  ret void
}

; CHECK-LABEL: to_ptr
;       CHECK: bytecast b64 %{{.*}} to i32*
define void @to_ptr(b64 %a) {
  %t = bytecast b64 %a to i32*
  ret void
}
