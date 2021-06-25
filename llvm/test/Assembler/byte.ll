; RUN: llvm-as < %s | llvm-dis | llvm-as | llvm-dis | FileCheck %s
; RUN: verify-uselistorder %s

; CHECK: @bytes(b1 %{{.*}}, b8 %{{.*}}, b16 %{{.*}}, b32 %{{.*}}, b64 %{{.*}}, b128 %{{.*}})
define void @bytes(b1 %a, b8 %b, b16 %c, b32 %d, b64 %e, b128 %f) {
    ret void
}

; =============================================================================
; Alloca, Load and Store
; =============================================================================

; CHECK-LABEL: byte_alloca
;       CHECK: alloca b8
;       CHECK: alloca b64
define void @byte_alloca() {
    %b1 = alloca b8, align 1
    %b8 = alloca b64, align 8
    ret void
}

; CHECK-LABEL: byte_load
;       CHECK: load b8, b8* %{{.*}}
define void @byte_load(b8* %ptr) {
    %val = load b8, b8* %ptr, align 1
    ret void
}

; CHECK-LABEL: byte_store
;       CHECK: store b8 %{{.*}}, b8* %{{.*}}
define void @byte_store(b8 %val, b8* %ptr) {
    store b8 %val, b8* %ptr, align 1
    ret void
}

; =============================================================================
; Trunc, ZExt and SExt
; =============================================================================

; CHECK-LABEL: trunc_to_byte
;       CHECK: trunc i64 %{{.*}} to b8
define b8 @trunc_to_byte(i64 %arg) {
  %res = trunc i64 %arg to b8
  ret b8 %res
}

; CHECK-LABEL: zext_to_byte
;       CHECK: zext i16 %{{.*}} to b64
define b64 @zext_to_byte(i16 %arg) {
  %res = zext i16 %arg to b64
  ret b64 %res
}

; CHECK-LABEL: sext_to_byte
;       CHECK: sext i16 %{{.*}} to b64
define b64 @sext_to_byte(i16 %arg) {
  %res = sext i16 %arg to b64
  ret b64 %res
}

; =============================================================================
; BitCast
; =============================================================================

; CHECK-LABEL: byte_bitcast
;       CHECK: bitcast i64 %{{.*}} to b64
;       CHECK: bitcast b64 %{{.*}} to <8 x b8>
;       CHECK: bitcast <8 x b8> %{{.*}} to <2 x b32>
;       CHECK: bitcast <2 x b32> %{{.*}} to b64
;       CHECK: bitcast i32* %{{.*}} to b8*
;       CHECK: bitcast b8* %{{.*}} to i64*
define void @byte_bitcast(i64 %i, b64 %s, i32* %ptr) {
  %s_to_s = bitcast i64 %i to b64
  %s_to_v = bitcast b64 %s to <8 x b8>
  %v_to_v = bitcast <8 x b8> %s_to_v to <2 x b32>
  %v_to_s = bitcast <2 x b32> %v_to_v to b64
  %b_ptr = bitcast i32* %ptr to b8*
  %i_ptr = bitcast b8* %b_ptr to i64*
  ret void
}

; =============================================================================
; PtrToInt
; =============================================================================

; CHECK-LABEL: ptr_to_byte
;       CHECK: ptrtoint i32* %{{.*}} to b64
define void @ptr_to_byte(i32* %ptr) {
  %b = ptrtoint i32* %ptr to b64
  ret void
}

; =============================================================================
; ByteCast
; =============================================================================

; CHECK-LABEL: bytecast_to_int
;       CHECK: bytecast b8 %{{.*}} to i8
;       CHECK: bytecast <4 x b8> %{{.*}} to <4 x i8>
define void @bytecast_to_int(b8 %byte, <4 x b8> %word) {
  %a = bytecast b8 %byte to i8
  %c = bytecast <4 x b8> %word to <4 x i8>
  ret void
}

; CHECK-LABEL: bytecast_to_ptr
;       CHECK: bytecast b8 %{{.*}} to i32*
;       CHECK: bytecast b64 %{{.*}} to i32*
define void @bytecast_to_ptr(b8 %byte1, b64 %byte2) {
  %a = bytecast b8 %byte1 to i32*
  %b = bytecast b64 %byte2 to i32*
  ret void
}

