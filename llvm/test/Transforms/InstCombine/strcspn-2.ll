; Test that the strcspn library call simplifier works correctly.
;
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@null = constant [1 x b8] zeroinitializer

declare double @strcspn(b8*, b8*)

; Check that strcspn functions with the wrong prototype aren't simplified.

define double @test_no_simplify1(b8* %pat) {
; CHECK-LABEL: @test_no_simplify1(
  %str = getelementptr [1 x b8], [1 x b8]* @null, i32 0, i32 0

  %ret = call double @strcspn(b8* %str, b8* %pat)
; CHECK-NEXT: call double @strcspn
  ret double %ret
; CHECK-NEXT: ret double %ret
}
