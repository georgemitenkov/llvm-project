; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; Test lib call simplification of __memcpy_chk calls with various values
; for dstlen and len.
;
; RUN: opt < %s -instcombine -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64"

%struct.T1 = type { [100 x i32], [100 x i32], [1024 x i8] }
%struct.T2 = type { [100 x i32], [100 x i32], [1024 x i8] }
%struct.T3 = type { [100 x i32], [100 x i32], [2048 x i8] }

@t1 = common global %struct.T1 zeroinitializer
@t2 = common global %struct.T2 zeroinitializer
@t3 = common global %struct.T3 zeroinitializer

; Check cases where dstlen >= len.

define b8* @test_simplify1() {
; CHECK-LABEL: @test_simplify1(
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* noundef nonnull align 4 dereferenceable(1824) bitcast (%struct.T1* @t1 to b8*), b8* noundef nonnull align 4 dereferenceable(1824) bitcast (%struct.T2* @t2 to b8*), i64 1824, i1 false)
; CHECK-NEXT:    ret b8* bitcast (%struct.T1* @t1 to b8*)
;
  %dst = bitcast %struct.T1* @t1 to b8*
  %src = bitcast %struct.T2* @t2 to b8*
  %ret = call b8* @__memcpy_chk(b8* %dst, b8* %src, i64 1824, i64 1824)
  ret b8* %ret
}

define b8* @test_simplify2() {
; CHECK-LABEL: @test_simplify2(
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* noundef nonnull align 4 dereferenceable(1824) bitcast (%struct.T1* @t1 to b8*), b8* noundef nonnull align 4 dereferenceable(1824) bitcast (%struct.T3* @t3 to b8*), i64 1824, i1 false)
; CHECK-NEXT:    ret b8* bitcast (%struct.T1* @t1 to b8*)
;
  %dst = bitcast %struct.T1* @t1 to b8*
  %src = bitcast %struct.T3* @t3 to b8*
  %ret = call b8* @__memcpy_chk(b8* %dst, b8* %src, i64 1824, i64 2848)
  ret b8* %ret
}

; Check cases where dstlen < len.

define b8* @test_no_simplify1() {
; CHECK-LABEL: @test_no_simplify1(
; CHECK-NEXT:    [[RET:%.*]] = call b8* @__memcpy_chk(b8* bitcast (%struct.T3* @t3 to b8*), b8* bitcast (%struct.T1* @t1 to b8*), i64 2848, i64 1824)
; CHECK-NEXT:    ret b8* [[RET]]
;
  %dst = bitcast %struct.T3* @t3 to b8*
  %src = bitcast %struct.T1* @t1 to b8*
  %ret = call b8* @__memcpy_chk(b8* %dst, b8* %src, i64 2848, i64 1824)
  ret b8* %ret
}

define b8* @test_no_simplify2() {
; CHECK-LABEL: @test_no_simplify2(
; CHECK-NEXT:    [[RET:%.*]] = call b8* @__memcpy_chk(b8* bitcast (%struct.T1* @t1 to b8*), b8* bitcast (%struct.T2* @t2 to b8*), i64 1024, i64 0)
; CHECK-NEXT:    ret b8* [[RET]]
;
  %dst = bitcast %struct.T1* @t1 to b8*
  %src = bitcast %struct.T2* @t2 to b8*
  %ret = call b8* @__memcpy_chk(b8* %dst, b8* %src, i64 1024, i64 0)
  ret b8* %ret
}

define b8* @test_simplify_return_indcall(b8* ()* %alloc) {
; CHECK-LABEL: @test_simplify_return_indcall(
; CHECK-NEXT:    [[DST:%.*]] = call b8* [[ALLOC:%.*]]()
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* noundef nonnull align 1 dereferenceable(1824) [[DST]], b8* noundef nonnull align 4 dereferenceable(1824) bitcast (%struct.T2* @t2 to b8*), i64 1824, i1 false)
; CHECK-NEXT:    ret b8* [[DST]]
;
  %src = bitcast %struct.T2* @t2 to b8*
  %dst = call b8* %alloc()
  %ret = call b8* @__memcpy_chk(b8* %dst, b8* %src, i64 1824, i64 1824)
  ret b8* %ret
}

define b8* @test_no_incompatible_attr(b8* %mem, i32 %val, i32 %size) {
; CHECK-LABEL: @test_no_incompatible_attr(
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* noundef nonnull align 4 dereferenceable(1824) bitcast (%struct.T1* @t1 to b8*), b8* noundef nonnull align 4 dereferenceable(1824) bitcast (%struct.T2* @t2 to b8*), i64 1824, i1 false)
; CHECK-NEXT:    ret b8* bitcast (%struct.T1* @t1 to b8*)
;
  %dst = bitcast %struct.T1* @t1 to b8*
  %src = bitcast %struct.T2* @t2 to b8*
  %ret = call dereferenceable(1) b8* @__memcpy_chk(b8* %dst, b8* %src, i64 1824, i64 1824)
  ret b8* %ret
}

declare b8* @__memcpy_chk(b8*, b8*, i64, i64)
