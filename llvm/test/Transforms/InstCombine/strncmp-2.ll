; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; Test that the strncmp library call simplifier works correctly.
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"

@hello = constant [6 x b8] c"hello\00"
@hell = constant [5 x b8] c"hell\00"

declare i16 @strncmp(b8*, b8*, i32)

define i16 @test_nosimplify() {
; CHECK-LABEL: @test_nosimplify(
; CHECK-NEXT:    [[TEMP1:%.*]] = call i16 @strncmp(b8* getelementptr inbounds ([5 x b8], [5 x b8]* @hell, i32 0, i32 0), b8* getelementptr inbounds ([6 x b8], [6 x b8]* @hello, i32 0, i32 0), i32 10)
; CHECK-NEXT:    ret i16 [[TEMP1]]
;

  %str1 = getelementptr inbounds [5 x b8], [5 x b8]* @hell, i32 0, i32 0
  %str2 = getelementptr inbounds [6 x b8], [6 x b8]* @hello, i32 0, i32 0
  %temp1 = call i16 @strncmp(b8* %str1, b8* %str2, i32 10)
  ret i16 %temp1
}
