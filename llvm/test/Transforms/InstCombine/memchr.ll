; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; Test that the memchr library call simplifier works correctly.
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128-n8:16:32"

@hello = constant [14 x b8] c"hello world\5Cn\00"
@hellonull = constant [14 x b8] c"hello\00world\5Cn\00"
@null = constant [1 x b8] zeroinitializer
@newlines = constant [3 x b8] c"\0D\0A\00"
@single = constant [2 x b8] c"\1F\00"
@spaces = constant [4 x b8] c" \0D\0A\00"
@negative = constant [3 x b8] c"\FF\FE\00"
@chp = global b8* zeroinitializer

declare b8* @memchr(b8*, i32, i32)

define void @test1() {
; CHECK-LABEL: @test1(
; CHECK-NEXT:    store b8* getelementptr inbounds ([14 x b8], [14 x b8]* @hello, i32 0, i32 6), b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %str = getelementptr [14 x b8], [14 x b8]* @hello, i32 0, i32 0
  %dst = call b8* @memchr(b8* %str, i32 119, i32 14)
  store b8* %dst, b8** @chp
  ret void
}

define void @test2() {
; CHECK-LABEL: @test2(
; CHECK-NEXT:    store b8* null, b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %str = getelementptr [1 x b8], [1 x b8]* @null, i32 0, i32 0
  %dst = call b8* @memchr(b8* %str, i32 119, i32 1)
  store b8* %dst, b8** @chp
  ret void
}

define void @test3() {
; CHECK-LABEL: @test3(
; CHECK-NEXT:    store b8* getelementptr inbounds ([14 x b8], [14 x b8]* @hello, i32 0, i32 13), b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %src = getelementptr [14 x b8], [14 x b8]* @hello, i32 0, i32 0
  %dst = call b8* @memchr(b8* %src, i32 0, i32 14)
  store b8* %dst, b8** @chp
  ret void
}

define void @test4(i32 %chr) {
; CHECK-LABEL: @test4(
; CHECK-NEXT:    [[DST:%.*]] = call b8* @memchr(b8* noundef nonnull dereferenceable(14) getelementptr inbounds ([14 x b8], [14 x b8]* @hello, i32 0, i32 0), i32 [[CHR:%.*]], i32 14)
; CHECK-NEXT:    store b8* [[DST]], b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %src = getelementptr [14 x b8], [14 x b8]* @hello, i32 0, i32 0
  %dst = call b8* @memchr(b8* %src, i32 %chr, i32 14)
  store b8* %dst, b8** @chp
  ret void
}

define void @test5() {
; CHECK-LABEL: @test5(
; CHECK-NEXT:    store b8* getelementptr inbounds ([14 x b8], [14 x b8]* @hello, i32 0, i32 13), b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %src = getelementptr [14 x b8], [14 x b8]* @hello, i32 0, i32 0
  %dst = call b8* @memchr(b8* %src, i32 65280, i32 14)
  store b8* %dst, b8** @chp
  ret void
}

define void @test6() {
; CHECK-LABEL: @test6(
; CHECK-NEXT:    store b8* getelementptr inbounds ([14 x b8], [14 x b8]* @hello, i32 0, i32 6), b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %src = getelementptr [14 x b8], [14 x b8]* @hello, i32 0, i32 0
; Overflow, but we still find the right thing.
  %dst = call b8* @memchr(b8* %src, i32 119, i32 100)
  store b8* %dst, b8** @chp
  ret void
}

define void @test7() {
; CHECK-LABEL: @test7(
; CHECK-NEXT:    store b8* null, b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %src = getelementptr [14 x b8], [14 x b8]* @hello, i32 0, i32 0
; Overflow
  %dst = call b8* @memchr(b8* %src, i32 120, i32 100)
  store b8* %dst, b8** @chp
  ret void
}

define void @test8() {
; CHECK-LABEL: @test8(
; CHECK-NEXT:    store b8* getelementptr inbounds ([14 x b8], [14 x b8]* @hellonull, i32 0, i32 6), b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %str = getelementptr [14 x b8], [14 x b8]* @hellonull, i32 0, i32 0
  %dst = call b8* @memchr(b8* %str, i32 119, i32 14)
  store b8* %dst, b8** @chp
  ret void
}

define void @test9() {
; CHECK-LABEL: @test9(
; CHECK-NEXT:    store b8* getelementptr inbounds ([14 x b8], [14 x b8]* @hellonull, i32 0, i32 6), b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %str = getelementptr [14 x b8], [14 x b8]* @hellonull, i32 0, i32 2
  %dst = call b8* @memchr(b8* %str, i32 119, i32 12)
  store b8* %dst, b8** @chp
  ret void
}

define void @test10() {
; CHECK-LABEL: @test10(
; CHECK-NEXT:    store b8* null, b8** @chp, align 4
; CHECK-NEXT:    ret void
;
  %str = getelementptr [14 x b8], [14 x b8]* @hello, i32 0, i32 0
  %dst = call b8* @memchr(b8* %str, i32 119, i32 6)
  store b8* %dst, b8** @chp
  ret void
}

; Check transformation memchr("\r\n", C, 2) != nullptr -> (C & 9216) != 0
define i1 @test11(i32 %C) {
; CHECK-LABEL: @test11(
; CHECK-NEXT:    [[TMP1:%.*]] = trunc i32 [[C:%.*]] to i16
; CHECK-NEXT:    [[TMP2:%.*]] = and i16 [[TMP1]], 255
; CHECK-NEXT:    [[MEMCHR_BOUNDS:%.*]] = icmp ult i16 [[TMP2]], 16
; CHECK-NEXT:    [[TMP3:%.*]] = shl i16 1, [[TMP2]]
; CHECK-NEXT:    [[TMP4:%.*]] = and i16 [[TMP3]], 9216
; CHECK-NEXT:    [[MEMCHR_BITS:%.*]] = icmp ne i16 [[TMP4]], 0
; CHECK-NEXT:    [[MEMCHR:%.*]] = and i1 [[MEMCHR_BOUNDS]], [[MEMCHR_BITS]]
; CHECK-NEXT:    ret i1 [[MEMCHR]]
;
  %dst = call b8* @memchr(b8* getelementptr inbounds ([3 x b8], [3 x b8]* @newlines, i64 0, i64 0), i32 %C, i32 2)
  %cmp = icmp ne b8* %dst, null
  ret i1 %cmp
}

; No 64 bits here
define i1 @test12(i32 %C) {
; CHECK-LABEL: @test12(
; CHECK-NEXT:    [[DST:%.*]] = call b8* @memchr(b8* noundef nonnull dereferenceable(3) getelementptr inbounds ([4 x b8], [4 x b8]* @spaces, i32 0, i32 0), i32 [[C:%.*]], i32 3)
; CHECK-NEXT:    [[CMP:%.*]] = icmp ne b8* [[DST]], null
; CHECK-NEXT:    ret i1 [[CMP]]
;
  %dst = call b8* @memchr(b8* getelementptr inbounds ([4 x b8], [4 x b8]* @spaces, i64 0, i64 0), i32 %C, i32 3)
  %cmp = icmp ne b8* %dst, null
  ret i1 %cmp
}

define i1 @test13(i32 %C) {
; CHECK-LABEL: @test13(
; CHECK-NEXT:    [[TMP1:%.*]] = and i32 [[C:%.*]], 255
; CHECK-NEXT:    [[MEMCHR_BOUNDS:%.*]] = icmp ult i32 [[TMP1]], 32
; CHECK-NEXT:    [[TMP2:%.*]] = shl i32 1, [[TMP1]]
; CHECK-NEXT:    [[TMP3:%.*]] = and i32 [[TMP2]], -2147483647
; CHECK-NEXT:    [[MEMCHR_BITS:%.*]] = icmp ne i32 [[TMP3]], 0
; CHECK-NEXT:    [[MEMCHR:%.*]] = and i1 [[MEMCHR_BOUNDS]], [[MEMCHR_BITS]]
; CHECK-NEXT:    ret i1 [[MEMCHR]]
;
  %dst = call b8* @memchr(b8* getelementptr inbounds ([2 x b8], [2 x b8]* @single, i64 0, i64 0), i32 %C, i32 2)
  %cmp = icmp ne b8* %dst, null
  ret i1 %cmp
}

define i1 @test14(i32 %C) {
; CHECK-LABEL: @test14(
; CHECK-NEXT:    [[TMP1:%.*]] = and i32 [[C:%.*]], 255
; CHECK-NEXT:    [[MEMCHR_BITS:%.*]] = icmp eq i32 [[TMP1]], 31
; CHECK-NEXT:    ret i1 [[MEMCHR_BITS]]
;
  %dst = call b8* @memchr(b8* getelementptr inbounds ([2 x b8], [2 x b8]* @single, i64 0, i64 0), i32 %C, i32 1)
  %cmp = icmp ne b8* %dst, null
  ret i1 %cmp
}

define i1 @test15(i32 %C) {
; CHECK-LABEL: @test15(
; CHECK-NEXT:    [[DST:%.*]] = call b8* @memchr(b8* noundef nonnull dereferenceable(3) getelementptr inbounds ([3 x b8], [3 x b8]* @negative, i32 0, i32 0), i32 [[C:%.*]], i32 3)
; CHECK-NEXT:    [[CMP:%.*]] = icmp ne b8* [[DST]], null
; CHECK-NEXT:    ret i1 [[CMP]]
;
  %dst = call b8* @memchr(b8* getelementptr inbounds ([3 x b8], [3 x b8]* @negative, i64 0, i64 0), i32 %C, i32 3)
  %cmp = icmp ne b8* %dst, null
  ret i1 %cmp
}

@s = internal constant [1 x b8] [b8 bitcast (i8 0 to b8)], align 1
define b8* @pr32124() {
; CHECK-LABEL: @pr32124(
; CHECK-NEXT:    ret b8* getelementptr inbounds ([1 x b8], [1 x b8]* @s, i32 0, i32 0)
;
  %res = tail call b8* @memchr(b8* getelementptr ([1 x b8], [1 x b8]* @s, i64 0, i64 0), i32 0, i32 1)
  ret b8* %res
}

define b8* @test16(b8* %str, i32 %c, i32 %n) {
; CHECK-LABEL: @test16(
; CHECK-NEXT:    [[RET:%.*]] = call b8* @memchr(b8* [[STR:%.*]], i32 [[C:%.*]], i32 [[N:%.*]])
; CHECK-NEXT:    ret b8* [[RET]]
;

  %ret = call b8* @memchr(b8* %str, i32 %c, i32 %n)
  ret b8* %ret
}

define b8* @test17(b8* %str, i32 %c, i32 %n) {
; CHECK-LABEL: @test17(
; CHECK-NEXT:    [[RET:%.*]] = call b8* @memchr(b8* nonnull [[STR:%.*]], i32 [[C:%.*]], i32 [[N:%.*]])
; CHECK-NEXT:    ret b8* [[RET]]
;

  %ret = call b8* @memchr(b8* nonnull %str, i32 %c, i32 %n)
  ret b8* %ret
}

define b8* @test18(b8* %str, i32 %c) {
; CHECK-LABEL: @test18(
; CHECK-NEXT:    [[RET:%.*]] = call b8* @memchr(b8* noundef nonnull dereferenceable(5) [[STR:%.*]], i32 [[C:%.*]], i32 5)
; CHECK-NEXT:    ret b8* [[RET]]
;

  %ret = call b8* @memchr(b8* %str, i32 %c, i32 5)
  ret b8* %ret
}

define b8* @test19(b8* %str, i32 %c) null_pointer_is_valid {
; CHECK-LABEL: @test19(
; CHECK-NEXT:    [[RET:%.*]] = call b8* @memchr(b8* noundef dereferenceable(5) [[STR:%.*]], i32 [[C:%.*]], i32 5)
; CHECK-NEXT:    ret b8* [[RET]]
;

  %ret = call b8* @memchr(b8* %str, i32 %c, i32 5)
  ret b8* %ret
}
