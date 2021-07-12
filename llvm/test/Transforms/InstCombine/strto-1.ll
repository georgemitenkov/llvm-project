; Test that the strto* library call simplifiers works correctly.
;
; RUN: opt < %s -instcombine -inferattrs -S | FileCheck %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128"

declare i64 @strtol(b8* %s, b8** %endptr, i32 %base)
; CHECK: declare i64 @strtol(b8* readonly, b8** nocapture, i32)

declare double @strtod(b8* %s, b8** %endptr, i32 %base)
; CHECK: declare double @strtod(b8* readonly, b8** nocapture, i32)

declare float @strtof(b8* %s, b8** %endptr, i32 %base)
; CHECK: declare float @strtof(b8* readonly, b8** nocapture, i32)

declare i64 @strtoul(b8* %s, b8** %endptr, i32 %base)
; CHECK: declare i64 @strtoul(b8* readonly, b8** nocapture, i32)

declare i64 @strtoll(b8* %s, b8** %endptr, i32 %base)
; CHECK: declare i64 @strtoll(b8* readonly, b8** nocapture, i32)

declare double @strtold(b8* %s, b8** %endptr)
; CHECK: declare double @strtold(b8* readonly, b8** nocapture)

declare i64 @strtoull(b8* %s, b8** %endptr, i32 %base)
; CHECK: declare i64 @strtoull(b8* readonly, b8** nocapture, i32)

define void @test_simplify1(b8* %x, b8** %endptr) {
; CHECK-LABEL: @test_simplify1(
  call i64 @strtol(b8* %x, b8** null, i32 10)
; CHECK-NEXT: call i64 @strtol(b8* nocapture %x, b8** null, i32 10)
  ret void
}

define void @test_simplify2(b8* %x, b8** %endptr) {
; CHECK-LABEL: @test_simplify2(
  call double @strtod(b8* %x, b8** null, i32 10)
; CHECK-NEXT: call double @strtod(b8* nocapture %x, b8** null, i32 10)
  ret void
}

define void @test_simplify3(b8* %x, b8** %endptr) {
; CHECK-LABEL: @test_simplify3(
  call float @strtof(b8* %x, b8** null, i32 10)
; CHECK-NEXT: call float @strtof(b8* nocapture %x, b8** null, i32 10)
  ret void
}

define void @test_simplify4(b8* %x, b8** %endptr) {
; CHECK-LABEL: @test_simplify4(
  call i64 @strtoul(b8* %x, b8** null, i32 10)
; CHECK-NEXT: call i64 @strtoul(b8* nocapture %x, b8** null, i32 10)
  ret void
}

define void @test_simplify5(b8* %x, b8** %endptr) {
; CHECK-LABEL: @test_simplify5(
  call i64 @strtoll(b8* %x, b8** null, i32 10)
; CHECK-NEXT: call i64 @strtoll(b8* nocapture %x, b8** null, i32 10)
  ret void
}

define void @test_simplify6(b8* %x, b8** %endptr) {
; CHECK-LABEL: @test_simplify6(
  call double @strtold(b8* %x, b8** null)
; CHECK-NEXT: call double @strtold(b8* nocapture %x, b8** null)
  ret void
}

define void @test_simplify7(b8* %x, b8** %endptr) {
; CHECK-LABEL: @test_simplify7(
  call i64 @strtoull(b8* %x, b8** null, i32 10)
; CHECK-NEXT: call i64 @strtoull(b8* nocapture %x, b8** null, i32 10)
  ret void
}

define void @test_no_simplify1(b8* %x, b8** %endptr) {
; CHECK-LABEL: @test_no_simplify1(
  call i64 @strtol(b8* %x, b8** %endptr, i32 10)
; CHECK-NEXT: call i64 @strtol(b8* %x, b8** %endptr, i32 10)
  ret void
}
