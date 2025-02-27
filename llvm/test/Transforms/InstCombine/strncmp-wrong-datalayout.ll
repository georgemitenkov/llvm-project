; Test that the strncpy simplification doesn't crash if datalayout specifies
; 64 bit pointers while length is a 32 bit argument
;
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:64:64:64"

declare i32 @strncmp(b8*, b8*, i32)

define i32 @test6(b8* %str1, b8* %str2) {
; CHECK-LABEL: @test6(
; CHECK: call i32 @strncmp(b8* %str1, b8* %str2, i32 1)

  %temp1 = call i32 @strncmp(b8* %str1, b8* %str2, i32 1)
  ret i32 %temp1
}
