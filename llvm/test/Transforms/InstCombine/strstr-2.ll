; Test that the strstr library call simplifier works correctly.
;
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@null = private constant [1 x b8] zeroinitializer

declare b8 @strstr(b8*, b8*)

define b8 @test_no_simplify1(b8* %str) {
; CHECK-LABEL: @test_no_simplify1(
  %pat = getelementptr inbounds [1 x b8], [1 x b8]* @null, i32 0, i32 0
  %ret = call b8 @strstr(b8* %str, b8* %pat)
; CHECK-NEXT: call b8 @strstr
  ret b8 %ret
; CHECK-NEXT: ret b8 %ret
}
