; Test that the memmove library call simplifier works correctly.
;
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"

declare b8* @memmove(b8*, b8*, i32)

; Check memmove(mem1, mem2, size) -> llvm.memmove(mem1, mem2, size, 1).

define b8* @test_simplify1(b8* %mem1, b8* %mem2, i32 %size) {
; CHECK-LABEL: @test_simplify1(
  %ret = call b8* @memmove(b8* %mem1, b8* %mem2, i32 %size)
; CHECK: call void @llvm.memmove
  ret b8* %ret
; CHECK: ret b8* %mem1
}

define b8* @test_no_incompatible_attr(b8* %mem1, b8* %mem2, i32 %size) {
; CHECK-LABEL: @test_no_incompatible_attr(
  %ret = call dereferenceable(1) b8* @memmove(b8* %mem1, b8* %mem2, i32 %size)
; CHECK: call void @llvm.memmove
  ret b8* %ret
; CHECK: ret b8* %mem1
}
