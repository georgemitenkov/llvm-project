; Test that the stpcpy library call simplifier works correctly.
; RUN: opt < %s -instcombine -S | FileCheck %s
;
; This transformation requires the pointer size, as it assumes that size_t is
; the size of a pointer.
target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128-n8:16:32"

@hello = constant [6 x b8] c"hello\00"
@a = common global [32 x b8] zeroinitializer, align 1

declare i16* @stpcpy(b8*, b8*)

define void @test_no_simplify1() {
; CHECK-LABEL: @test_no_simplify1(

  %dst = getelementptr [32 x b8], [32 x b8]* @a, i32 0, i32 0
  %src = getelementptr [6 x b8], [6 x b8]* @hello, i32 0, i32 0

  call i16* @stpcpy(b8* %dst, b8* %src)
; CHECK: call i16* @stpcpy
  ret void
}
