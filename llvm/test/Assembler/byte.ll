; RUN: llvm-as < %s | llvm-dis | llvm-as | llvm-dis | FileCheck %s
; RUN: verify-uselistorder %s


; CHECK: common global [32 x b8] zeroinitializer
; CHECK: constant [1 x b8] zeroinitializer
; CHECK: constant [2 x b8] [b8 bitcast (i8 1 to b8), b8 bitcast (i8 2 to b8)]
@a = common global [32 x b8] zeroinitializer, align 1
@b = constant [1 x b8] zeroinitializer
@c = constant [2 x b8] [b8 bitcast (i8 1 to b8), b8 bitcast (i8 2 to b8)]

; CHECK: @bytes(b1 %{{.*}}, b8 %{{.*}}, b16 %{{.*}}, b32 %{{.*}}, b64 %{{.*}}, b128 %{{.*}})
define void @bytes(b1 %a, b8 %b, b16 %c, b32 %d, b64 %e, b128 %f) {
    ret void
}

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

; CHECK-LABEL: bitcasts
;       CHECK: bitcast i64 %{{.*}} to b64
;       CHECK: bitcast b64 %{{.*}} to <8 x b8>
;       CHECK: bitcast <8 x b8> %{{.*}} to <2 x b32>
;       CHECK: bitcast <2 x b32> %{{.*}} to b64
;       CHECK: bitcast i32* %{{.*}} to b8*
;       CHECK: bitcast b8* %{{.*}} to i64*
define void @bitcasts(i64 %i, b64 %s, i32* %ptr) {
  %s_to_s = bitcast i64 %i to b64
  %s_to_v = bitcast b64 %s to <8 x b8>
  %v_to_v = bitcast <8 x b8> %s_to_v to <2 x b32>
  %v_to_s = bitcast <2 x b32> %v_to_v to b64
  %b_ptr = bitcast i32* %ptr to b8*
  %i_ptr = bitcast b8* %b_ptr to i64*
  ret void
}

; CHECK-LABEL: byte_constant
;       CHECK: store b8 bitcast (i8 0 to b8), b8* %{{.*}}
define void @byte_constant(b8* %ptr) {
    store b8 bitcast (i8 0 to b8), b8* %ptr, align 1
    ret void
}
