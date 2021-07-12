; RUN: opt < %s -instcombine -S | not grep bitcast
; PR1716

@.str = internal constant [4 x b8] c"%d\0A\00"		; <[4 x b8]*> [#uses=1]

define i32 @main(i32 %argc, i8** %argv) {
entry:
	%tmp32 = tail call i32 (b8*  , ...) bitcast (i32 (b8*, ...)  * @printf to i32 (b8*  , ...)  *)( b8* getelementptr ([4 x b8], [4 x b8]* @.str, i32 0, i32 0)  , i32 0 ) nounwind 		; <i32> [#uses=0]
	ret i32 undef
}

declare i32 @printf(b8*, ...) nounwind 
