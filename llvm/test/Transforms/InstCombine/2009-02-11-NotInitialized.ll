; RUN: opt < %s -inline -instcombine -function-attrs | llvm-dis
;
; Check that nocapture attributes are added when run after an SCC pass.
; PR3520

define i32 @use(b8* %x) nounwind readonly {
; CHECK: @use(b8* nocapture %x)
  %1 = tail call i64 @strlen(b8* %x) nounwind readonly
  %2 = trunc i64 %1 to i32
  ret i32 %2
}

declare i64 @strlen(b8*) nounwind readonly
; CHECK: declare i64 @strlen(b8* nocapture) nounwind readonly
