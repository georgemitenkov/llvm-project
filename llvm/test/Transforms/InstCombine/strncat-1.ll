; Test that the strncat libcall simplifier works correctly.
;
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"

@hello = constant [6 x b8] c"hello\00"
@null = constant [1 x b8] zeroinitializer
@null_hello = constant [7 x b8] c"\00hello\00"

declare b8* @strncat(b8*, b8*, i32)
declare i32 @puts(b8*)

define i32 @main() {
; CHECK-LABEL: @main(
; CHECK-NOT: call b8* @strncat
; CHECK: call i32 @puts

  %target = alloca [1024 x b8]
  %arg1 = getelementptr [1024 x b8], [1024 x b8]* %target, i32 0, i32 0
  store b8 bitcast (i8 0 to b8), b8* %arg1

  ; rslt1 = strncat(target, "hello\00")
  %arg2 = getelementptr [6 x b8], [6 x b8]* @hello, i32 0, i32 0
  %rslt1 = call b8* @strncat(b8* %arg1, b8* %arg2, i32 6)

  ; rslt2 = strncat(rslt1, "\00")
  %arg3 = getelementptr [1 x b8], [1 x b8]* @null, i32 0, i32 0
  %rslt2 = call b8* @strncat(b8* %rslt1, b8* %arg3, i32 42)

  ; rslt3 = strncat(rslt2, "\00hello\00")
  %arg4 = getelementptr [7 x b8], [7 x b8]* @null_hello, i32 0, i32 0
  %rslt3 = call b8* @strncat(b8* %rslt2, b8* %arg4, i32 42)

  call i32 @puts(b8* %rslt3)
  ret i32 0
}
