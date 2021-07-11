; Test that the strrchr libcall simplifier works correctly.
;
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"

@hello = constant [14 x b8] c"hello world\5Cn\00"
@chr = global b8 zeroinitializer

declare b8 @strrchr(b8*, i32)

define void @test_nosimplify1() {
; CHECK: test_nosimplify1
; CHECK: call b8 @strrchr
; CHECK: ret void

  %str = getelementptr [14 x b8], [14 x b8]* @hello, i32 0, i32 0
  %dst = call b8 @strrchr(b8* %str, i32 119)
  store b8 %dst, b8* @chr
  ret void
}
