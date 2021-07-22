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

; CHECK-LABEL: trunc_to_byte
;       CHECK: trunc i64 %{{.*}} to b8
define void @trunc_to_byte(i64 %i) {
    %byte = trunc i64 %i to b8
    ret void
}

; CHECK-LABEL: sext_to_byte
;       CHECK: sext i8 %{{.*}} to b16
define void @sext_to_byte(i8 %i) {
    %byte = sext i8 %i to b16
    ret void
}

; CHECK-LABEL: zext_to_byte
;       CHECK: zext i8 %{{.*}} to b16
define void @zext_to_byte(i8 %i) {
    %byte = zext i8 %i to b16
    ret void
}

; CHECK-LABEL: bitcast_to_byte
;       CHECK: bitcast i8 %{{.*}} to b8
define void @bitcast_to_byte(i8 %i) {
    %byte = bitcast i8 %i to b8
    ret void
}

; CHECK-LABEL: byte_constant
;       CHECK: store b8 bitcast (i8 0 to b8), b8* %{{.*}}
define void @byte_constant(b8* %ptr) {
    store b8 bitcast (i8 0 to b8), b8* %ptr, align 1
    ret void
}
