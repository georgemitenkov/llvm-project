; RUN: llvm-as < %s | llvm-dis | llvm-as | llvm-dis | FileCheck %s
; RUN: verify-uselistorder %s

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
