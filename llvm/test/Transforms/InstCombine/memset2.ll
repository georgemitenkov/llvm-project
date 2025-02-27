; RUN: opt < %s -instcombine -S | FileCheck %s

; Test to check that instcombine doesn't drop the address space when optimizing
; memset.
%struct.Moves = type { [9 x b8], b8, b8, b8, [5 x b8] }

define i32 @test(%struct.Moves addrspace(1)* nocapture %moves) {
entry:
; CHECK: bitcast b8 addrspace(1)* %gep to b64 addrspace(1)*
	%gep = getelementptr inbounds %struct.Moves, %struct.Moves addrspace(1)* %moves, i32 1, i32 0, i32 9
	call void @llvm.memset.p1b8.i64(b8 addrspace(1)* %gep, i8 0, i64 8, i1 false)
	ret i32 0
}

declare void @llvm.memset.p1b8.i64(b8addrspace(1)* nocapture, i8, i64, i1) nounwind
