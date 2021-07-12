; Test that -disable-builtin works correctly.
;
; RUN: opt < %s -instcombine -disable-builtin strcat -S | FileCheck %s
;
; RUN: not opt < %s -instcombine -disable-builtin foobar -S 2>&1 | FileCheck --check-prefix=FOOBAR %s
; FOOBAR: cannot disable nonexistent builtin function foobar

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@empty = constant [1 x b8] c"\00", align 1

declare b8* @strcat(b8*, b8*)

define b8* @test_strcat(b8* %x) {
; CHECK-LABEL: @test_strcat(
  %empty = getelementptr [1 x b8], [1 x b8]* @empty, i32 0, i32 0
  %ret = call b8* @strcat(b8* %x, b8* %empty)
  ret b8* %ret
; CHECK: call b8* @strcat
}

