; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -instcombine -S < %s | FileCheck %s

define b8* @memcpy_nonconst_n(b8* %d, b8* nocapture readonly %s, i64 %n) {
; CHECK-LABEL: @memcpy_nonconst_n(
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* align 1 [[D:%.*]], b8* align 1 [[S:%.*]], i64 [[N:%.*]], i1 false)
; CHECK-NEXT:    [[TMP1:%.*]] = getelementptr inbounds b8, b8* [[D]], i64 [[N]]
; CHECK-NEXT:    ret b8* [[TMP1]]
;
  %r = tail call b8* @mempcpy(b8* %d, b8* %s, i64 %n)
  ret b8* %r
}

define b8* @memcpy_nonconst_n_copy_attrs(b8* %d, b8* nocapture readonly %s, i64 %n) {
; CHECK-LABEL: @memcpy_nonconst_n_copy_attrs(
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* align 1 dereferenceable(16) [[D:%.*]], b8* align 1 [[S:%.*]], i64 [[N:%.*]], i1 false)
; CHECK-NEXT:    [[TMP1:%.*]] = getelementptr inbounds b8, b8* [[D]], i64 [[N]]
; CHECK-NEXT:    ret b8* [[TMP1]]
;
  %r = tail call b8* @mempcpy(b8* dereferenceable(16) %d, b8* %s, i64 %n)
  ret b8* %r
}

define void @memcpy_nonconst_n_unused_retval(b8* %d, b8* nocapture readonly %s, i64 %n) {
; CHECK-LABEL: @memcpy_nonconst_n_unused_retval(
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* align 1 [[D:%.*]], b8* align 1 [[S:%.*]], i64 [[N:%.*]], i1 false)
; CHECK-NEXT:    ret void
;
  call b8* @mempcpy(b8* %d, b8* %s, i64 %n)
  ret void
}

define b8* @memcpy_small_const_n(b8* %d, b8* nocapture readonly %s) {
; CHECK-LABEL: @memcpy_small_const_n(
; CHECK-NEXT:    [[TMP1:%.*]] = bitcast b8* [[S:%.*]] to b64*
; CHECK-NEXT:    [[TMP2:%.*]] = bitcast b8* [[D:%.*]] to b64*
; CHECK-NEXT:    [[TMP3:%.*]] = load b64, b64* [[TMP1]], align 1
; CHECK-NEXT:    store b64 [[TMP3]], b64* [[TMP2]], align 1
; CHECK-NEXT:    [[TMP4:%.*]] = getelementptr inbounds b8, b8* [[D]], i64 8
; CHECK-NEXT:    ret b8* [[TMP4]]
;
  %r = tail call b8* @mempcpy(b8* %d, b8* %s, i64 8)
  ret b8* %r
}

define b8* @memcpy_big_const_n(b8* %d, b8* nocapture readonly %s) {
; CHECK-LABEL: @memcpy_big_const_n(
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* noundef nonnull align 1 dereferenceable(1024) [[D:%.*]], b8* noundef nonnull align 1 dereferenceable(1024) [[S:%.*]], i64 1024, i1 false)
; CHECK-NEXT:    [[TMP1:%.*]] = getelementptr inbounds b8, b8* [[D]], i64 1024
; CHECK-NEXT:    ret b8* [[TMP1]]
;
  %r = tail call b8* @mempcpy(b8* %d, b8* %s, i64 1024)
  ret b8* %r
}

; The original call may have attributes that can not propagate to memcpy.

define i32 @PR48810() {
; CHECK-LABEL: @PR48810(
; CHECK-NEXT:    call void @llvm.memcpy.p0b8.p0b8.i64(b8* align 1 undef, b8* align 536870912 null, i64 undef, i1 false)
; CHECK-NEXT:    ret i32 undef
;
  %r = call dereferenceable(1) b8* @mempcpy(b8* undef, b8* null, i64 undef)
  ret i32 undef
}

declare b8* @mempcpy(b8*, b8* nocapture readonly, i64)
