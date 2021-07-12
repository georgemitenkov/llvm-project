; Test that the memcmp library call simplifier works correctly.
;
; RUN: opt < %s -instcombine -S | FileCheck --check-prefix=CHECK --check-prefix=NOBCMP %s
; RUN: opt < %s -instcombine -mtriple=x86_64-unknown-linux-gnu -S | FileCheck --check-prefix=CHECK --check-prefix=BCMP %s

target datalayout = "e-p:32:32:32-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:32:64-f32:32:32-f64:32:64-v64:64:64-v128:128:128-a0:0:64-f80:128:128-n8:16:32:64"

@foo = constant [4 x b8] c"foo\00"
@hel = constant [4 x b8] c"hel\00"
@hello_u = constant [8 x b8] c"hello_u\00"

declare i32 @memcmp(b8*, b8*, i32)

; Check memcmp(mem, mem, size) -> 0.

define i32 @test_simplify1(b8* %mem, i32 %size) {
; CHECK-LABEL: @test_simplify1(
; CHECK-NEXT:    ret i32 0
;
  %ret = call i32 @memcmp(b8* %mem, b8* %mem, i32 %size)
  ret i32 %ret
}

; Check memcmp(mem1, mem2, 0) -> 0.

define i32 @test_simplify2(b8* %mem1, b8* %mem2) {
; CHECK-LABEL: @test_simplify2(
; CHECK-NEXT:    ret i32 0
;
  %ret = call i32 @memcmp(b8* %mem1, b8* %mem2, i32 0)
  ret i32 %ret
}

;; Check memcmp(mem1, mem2, 1) -> *(unsigned char*)mem1 - *(unsigned char*)mem2.

define i32 @test_simplify3(b8* %mem1, b8* %mem2) {
; CHECK-LABEL: @test_simplify3(
; CHECK-NEXT:    [[LHSC:%.*]] = load b8, b8* %mem1, align 1
; CHECK-NEXT:    [[LHSV1:%.*]] = bytecast b8 [[LHSC]] to i8
; CHECK-NEXT:    [[LHSV2:%.*]] = zext i8 [[LHSV1]] to i32
; CHECK-NEXT:    [[RHSC:%.*]] = load b8, b8* %mem2, align 1
; CHECK-NEXT:    [[RHSV1:%.*]] = bytecast b8 [[RHSC]] to i8
; CHECK-NEXT:    [[RHSV2:%.*]] = zext i8 [[RHSV1]] to i32
; CHECK-NEXT:    [[CHARDIFF:%.*]] = sub nsw i32 [[LHSV2]], [[RHSV2]]
; CHECK-NEXT:    ret i32 [[CHARDIFF]]
;
  %ret = call i32 @memcmp(b8* %mem1, b8* %mem2, i32 1)
  ret i32 %ret
}

; Check memcmp(mem1, mem2, size) -> cnst, where all arguments are constants.

define i32 @test_simplify4() {
; CHECK-LABEL: @test_simplify4(
; CHECK-NEXT:    ret i32 0
;
  %mem1 = getelementptr [4 x b8], [4 x b8]* @hel, i32 0, i32 0
  %mem2 = getelementptr [8 x b8], [8 x b8]* @hello_u, i32 0, i32 0
  %ret = call i32 @memcmp(b8* %mem1, b8* %mem2, i32 3)
  ret i32 %ret
}

define i32 @test_simplify5() {
; CHECK-LABEL: @test_simplify5(
; CHECK-NEXT:    ret i32 1
;
  %mem1 = getelementptr [4 x b8], [4 x b8]* @hel, i32 0, i32 0
  %mem2 = getelementptr [4 x b8], [4 x b8]* @foo, i32 0, i32 0
  %ret = call i32 @memcmp(b8* %mem1, b8* %mem2, i32 3)
  ret i32 %ret
}

define i32 @test_simplify6() {
; CHECK-LABEL: @test_simplify6(
; CHECK-NEXT:    ret i32 -1
;
  %mem1 = getelementptr [4 x b8], [4 x b8]* @foo, i32 0, i32 0
  %mem2 = getelementptr [4 x b8], [4 x b8]* @hel, i32 0, i32 0
  %ret = call i32 @memcmp(b8* %mem1, b8* %mem2, i32 3)
  ret i32 %ret
}

; Check memcmp(mem1, mem2, 8)==0 -> *(int64_t*)mem1 == *(int64_t*)mem2

define i1 @test_simplify7(i64 %x, i64 %y) {
; CHECK-LABEL: @test_simplify7(
; CHECK-NEXT:    [[LHSV1:%.*]] = bitcast i64 [[X:%.*]] to b64
; CHECK-NEXT:    [[RHSV1:%.*]] = bitcast i64 [[Y:%.*]] to b64
; CHECK-NEXT:    [[LHSV2:%.*]] = bytecast b64 [[LHSV1]] to i64
; CHECK-NEXT:    [[RHSV2:%.*]] = bytecast b64 [[RHSV1]] to i64
; CHECK-NEXT:    [[CMP:%.*]] = icmp eq i64 [[LHSV2]], [[RHSV2]]
; CHECK-NEXT:    ret i1 [[CMP]]
;
  %x.addr = alloca i64, align 8
  %y.addr = alloca i64, align 8
  store i64 %x, i64* %x.addr, align 8
  store i64 %y, i64* %y.addr, align 8
  %xptr = bitcast i64* %x.addr to b8*
  %yptr = bitcast i64* %y.addr to b8*
  %call = call i32 @memcmp(b8* %xptr, b8* %yptr, i32 8)
  %cmp = icmp eq i32 %call, 0
  ret i1 %cmp
}

; Check memcmp(mem1, mem2, 4)==0 -> *(int32_t*)mem1 == *(int32_t*)mem2

define i1 @test_simplify8(i32 %x, i32 %y) {
; CHECK-LABEL: @test_simplify8(
; CHECK-NEXT:    [[LHSV1:%.*]] = bitcast i32 [[X:%.*]] to b32
; CHECK-NEXT:    [[RHSV1:%.*]] = bitcast i32 [[Y:%.*]] to b32
; CHECK-NEXT:    [[LHSV2:%.*]] = bytecast b32 [[LHSV1]] to i32
; CHECK-NEXT:    [[RHSV2:%.*]] = bytecast b32 [[RHSV1]] to i32
; CHECK-NEXT:    [[CMP:%.*]] = icmp eq i32 [[LHSV2]], [[RHSV2]]
; CHECK-NEXT:    ret i1 [[CMP]]
;
  %x.addr = alloca i32, align 4
  %y.addr = alloca i32, align 4
  store i32 %x, i32* %x.addr, align 4
  store i32 %y, i32* %y.addr, align 4
  %xptr = bitcast i32* %x.addr to b8*
  %yptr = bitcast i32* %y.addr to b8*
  %call = call i32 @memcmp(b8* %xptr, b8* %yptr, i32 4)
  %cmp = icmp eq i32 %call, 0
  ret i1 %cmp
}

; Check memcmp(mem1, mem2, 2)==0 -> *(int16_t*)mem1 == *(int16_t*)mem2

define i1 @test_simplify9(i16 %x, i16 %y) {
; CHECK-LABEL: @test_simplify9(
; CHECK-NEXT:    [[LHSV1:%.*]] = bitcast i16 [[X:%.*]] to b16
; CHECK-NEXT:    [[RHSV1:%.*]] = bitcast i16 [[Y:%.*]] to b16
; CHECK-NEXT:    [[LHSV2:%.*]] = bytecast b16 [[LHSV1]] to i16
; CHECK-NEXT:    [[RHSV2:%.*]] = bytecast b16 [[RHSV1]] to i16
; CHECK-NEXT:    [[CMP:%.*]] = icmp eq i16 [[LHSV2]], [[RHSV2]]
; CHECK-NEXT:    ret i1 [[CMP]]
;
  %x.addr = alloca i16, align 2
  %y.addr = alloca i16, align 2
  store i16 %x, i16* %x.addr, align 2
  store i16 %y, i16* %y.addr, align 2
  %xptr = bitcast i16* %x.addr to b8*
  %yptr = bitcast i16* %y.addr to b8*
  %call = call i32 @memcmp(b8* %xptr, b8* %yptr, i32 2)
  %cmp = icmp eq i32 %call, 0
  ret i1 %cmp
}

; Check memcmp(mem1, mem2, size)==0 -> bcmp(mem1, mem2, size)==0

define i1 @test_simplify10(b8* %mem1, b8* %mem2, i32 %size) {
; NOBCMP-LABEL: @test_simplify10(
; NOBCMP-NEXT:    [[CALL:%.*]] = call i32 @memcmp(b8* %mem1, b8* %mem2, i32 %size)
; NOBCMP-NEXT:    [[CMP:%.*]] = icmp eq i32 [[CALL]], 0
; NOBCMP-NEXT:    ret i1 [[CMP]]
;
; BCMP-LABEL: @test_simplify10(
; BCMP-NEXT:    [[CALL:%.*]] = call i32 @bcmp(b8* %mem1, b8* %mem2, i32 %size)
; BCMP-NEXT:    [[CMP:%.*]] = icmp eq i32 [[CALL]], 0
; BCMP-NEXT:    ret i1 [[CMP]]
;
  %call = call i32 @memcmp(b8* %mem1, b8* %mem2, i32 %size)
  %cmp = icmp eq i32 %call, 0
  ret i1 %cmp
}
