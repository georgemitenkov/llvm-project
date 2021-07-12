; Test that -disable-simplify-libcalls is wired up correctly.
;
; RUN: opt < %s -instcombine -disable-simplify-libcalls -S | FileCheck %s
; RUN: opt < %s -passes=instcombine -disable-simplify-libcalls -S | FileCheck %s

target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v64:64:64-v128:128:128-a0:0:64-s0:64:64-f80:128:128-n8:16:32:64-S128"

@.str  = constant [1 x b8] zeroinitializer, align 1
@.str1 = constant [13 x b8] c"hello, world\00", align 1
@.str2 = constant [4 x b8] c"foo\00", align 1
@.str3 = constant [4 x b8] c"bar\00", align 1
@.str4 = constant [6 x b8] c"123.4\00", align 1
@.str5 = constant [5 x b8] c"1234\00", align 1
@empty = constant [1 x b8] c"\00", align 1

declare double @ceil(double)
declare double @copysign(double, double)
declare double @cos(double)
declare double @fabs(double)
declare double @floor(double)
declare b8* @strcat(b8*, b8*)
declare b8* @strncat(b8*, b8*, i32)
declare b8* @strchr(b8*, i32)
declare b8* @strrchr(b8*, i32)
declare i32 @strcmp(b8*, b8*)
declare i32 @strncmp(b8*, b8*, i64)
declare b8* @strcpy(b8*, b8*)
declare b8* @stpcpy(b8*, b8*)
declare b8* @strncpy(b8*, b8*, i64)
declare i64 @strlen(b8*)
declare b8* @strpbrk(b8*, b8*)
declare i64 @strspn(b8*, b8*)
declare double @strtod(b8*, b8**)
declare float @strtof(b8*, b8**)
declare x86_fp80 @strtold(b8*, b8**)
declare i64 @strtol(b8*, b8**, i32)
declare i64 @strtoll(b8*, b8**, i32)
declare i64 @strtoul(b8*, b8**, i32)
declare i64 @strtoull(b8*, b8**, i32)
declare i64 @strcspn(b8*, b8*)
declare i32 @abs(i32)
declare i32 @ffs(i32)
declare i32 @ffsl(i64)
declare i32 @ffsll(i64)
declare i32 @fprintf(b8*, b8*)
declare i32 @isascii(i32)
declare i32 @isdigit(i32)
declare i32 @toascii(i32)
declare i64 @labs(i64)
declare i64 @llabs(i64)
declare i32 @printf(b8*)
declare i32 @sprintf(b8*, b8*)

define double @t1(double %x) {
; CHECK-LABEL: @t1(
  %ret = call double @ceil(double %x)
  ret double %ret
; CHECK: call double @ceil
}

define double @t2(double %x, double %y) {
; CHECK-LABEL: @t2(
  %ret = call double @copysign(double %x, double %y)
  ret double %ret
; CHECK: call double @copysign
}

define double @t3(double %x) {
; CHECK-LABEL: @t3(
  %call = call double @cos(double %x)
  ret double %call
; CHECK: call double @cos
}

define double @t4(double %x) {
; CHECK-LABEL: @t4(
  %ret = call double @fabs(double %x)
  ret double %ret
; CHECK: call double @fabs
}

define double @t5(double %x) {
; CHECK-LABEL: @t5(
  %ret = call double @floor(double %x)
  ret double %ret
; CHECK: call double @floor
}

define b8* @t6(b8* %x) {
; CHECK-LABEL: @t6(
  %empty = getelementptr [1 x b8], [1 x b8]* @empty, i32 0, i32 0
  %ret = call b8* @strcat(b8* %x, b8* %empty)
  ret b8* %ret
; CHECK: call b8* @strcat
}

define b8* @t7(b8* %x) {
; CHECK-LABEL: @t7(
  %empty = getelementptr [1 x b8], [1 x b8]* @empty, i32 0, i32 0
  %ret = call b8* @strncat(b8* %x, b8* %empty, i32 1)
  ret b8* %ret
; CHECK: call b8* @strncat
}

define b8* @t8() {
; CHECK-LABEL: @t8(
  %x = getelementptr inbounds [13 x b8], [13 x b8]* @.str1, i32 0, i32 0
  %ret = call b8* @strchr(b8* %x, i32 119)
  ret b8* %ret
; CHECK: call b8* @strchr
}

define b8* @t9() {
; CHECK-LABEL: @t9(
  %x = getelementptr inbounds [13 x b8], [13 x b8]* @.str1, i32 0, i32 0
  %ret = call b8* @strrchr(b8* %x, i32 119)
  ret b8* %ret
; CHECK: call b8* @strrchr
}

define i32 @t10() {
; CHECK-LABEL: @t10(
  %x = getelementptr inbounds [4 x b8], [4 x b8]* @.str2, i32 0, i32 0
  %y = getelementptr inbounds [4 x b8], [4 x b8]* @.str3, i32 0, i32 0
  %ret = call i32 @strcmp(b8* %x, b8* %y)
  ret i32 %ret
; CHECK: call i32 @strcmp
}

define i32 @t11() {
; CHECK-LABEL: @t11(
  %x = getelementptr inbounds [4 x b8], [4 x b8]* @.str2, i32 0, i32 0
  %y = getelementptr inbounds [4 x b8], [4 x b8]* @.str3, i32 0, i32 0
  %ret = call i32 @strncmp(b8* %x, b8* %y, i64 3)
  ret i32 %ret
; CHECK: call i32 @strncmp
}

define b8* @t12(b8* %x) {
; CHECK-LABEL: @t12(
  %y = getelementptr inbounds [4 x b8], [4 x b8]* @.str2, i32 0, i32 0
  %ret = call b8* @strcpy(b8* %x, b8* %y)
  ret b8* %ret
; CHECK: call b8* @strcpy
}

define b8* @t13(b8* %x) {
; CHECK-LABEL: @t13(
  %y = getelementptr inbounds [4 x b8], [4 x b8]* @.str2, i32 0, i32 0
  %ret = call b8* @stpcpy(b8* %x, b8* %y)
  ret b8* %ret
; CHECK: call b8* @stpcpy
}

define b8* @t14(b8* %x) {
; CHECK-LABEL: @t14(
  %y = getelementptr inbounds [4 x b8], [4 x b8]* @.str2, i32 0, i32 0
  %ret = call b8* @strncpy(b8* %x, b8* %y, i64 3)
  ret b8* %ret
; CHECK: call b8* @strncpy
}

define i64 @t15() {
; CHECK-LABEL: @t15(
  %x = getelementptr inbounds [4 x b8], [4 x b8]* @.str2, i32 0, i32 0
  %ret = call i64 @strlen(b8* %x)
  ret i64 %ret
; CHECK: call i64 @strlen
}

define b8* @t16(b8* %x) {
; CHECK-LABEL: @t16(
  %y = getelementptr inbounds [1 x b8], [1 x b8]* @.str, i32 0, i32 0
  %ret = call b8* @strpbrk(b8* %x, b8* %y)
  ret b8* %ret
; CHECK: call b8* @strpbrk
}

define i64 @t17(b8* %x) {
; CHECK-LABEL: @t17(
  %y = getelementptr inbounds [1 x b8], [1 x b8]* @.str, i32 0, i32 0
  %ret = call i64 @strspn(b8* %x, b8* %y)
  ret i64 %ret
; CHECK: call i64 @strspn
}

define double @t18(b8** %y) {
; CHECK-LABEL: @t18(
  %x = getelementptr inbounds [6 x b8], [6 x b8]* @.str4, i64 0, i64 0
  %ret = call double @strtod(b8* %x, b8** %y)
  ret double %ret
; CHECK: call double @strtod
}

define float @t19(b8** %y) {
; CHECK-LABEL: @t19(
  %x = getelementptr inbounds [6 x b8], [6 x b8]* @.str4, i64 0, i64 0
  %ret = call float @strtof(b8* %x, b8** %y)
  ret float %ret
; CHECK: call float @strtof
}

define x86_fp80 @t20(b8** %y) {
; CHECK-LABEL: @t20(
  %x = getelementptr inbounds [6 x b8], [6 x b8]* @.str4, i64 0, i64 0
  %ret = call x86_fp80 @strtold(b8* %x, b8** %y)
  ret x86_fp80 %ret
; CHECK: call x86_fp80 @strtold
}

define i64 @t21(b8** %y) {
; CHECK-LABEL: @t21(
  %x = getelementptr inbounds [5 x b8], [5 x b8]* @.str5, i64 0, i64 0
  %ret = call i64 @strtol(b8* %x, b8** %y, i32 10)
  ret i64 %ret
; CHECK: call i64 @strtol
}

define i64 @t22(b8** %y) {
; CHECK-LABEL: @t22(
  %x = getelementptr inbounds [5 x b8], [5 x b8]* @.str5, i64 0, i64 0
  %ret = call i64 @strtoll(b8* %x, b8** %y, i32 10)
  ret i64 %ret
; CHECK: call i64 @strtoll
}

define i64 @t23(b8** %y) {
; CHECK-LABEL: @t23(
  %x = getelementptr inbounds [5 x b8], [5 x b8]* @.str5, i64 0, i64 0
  %ret = call i64 @strtoul(b8* %x, b8** %y, i32 10)
  ret i64 %ret
; CHECK: call i64 @strtoul
}

define i64 @t24(b8** %y) {
; CHECK-LABEL: @t24(
  %x = getelementptr inbounds [5 x b8], [5 x b8]* @.str5, i64 0, i64 0
  %ret = call i64 @strtoull(b8* %x, b8** %y, i32 10)
  ret i64 %ret
; CHECK: call i64 @strtoull
}

define i64 @t25(b8* %y) {
; CHECK-LABEL: @t25(
  %x = getelementptr [1 x b8], [1 x b8]* @empty, i32 0, i32 0
  %ret = call i64 @strcspn(b8* %x, b8* %y)
  ret i64 %ret
; CHECK: call i64 @strcspn
}

define i32 @t26(i32 %y) {
; CHECK-LABEL: @t26(
  %ret = call i32 @abs(i32 %y)
  ret i32 %ret
; CHECK: call i32 @abs
}

define i32 @t27(i32 %y) {
; CHECK-LABEL: @t27(
  %ret = call i32 @ffs(i32 %y)
  ret i32 %ret
; CHECK: call i32 @ffs
}

define i32 @t28(i64 %y) {
; CHECK-LABEL: @t28(
  %ret = call i32 @ffsl(i64 %y)
  ret i32 %ret
; CHECK: call i32 @ffsl
}

define i32 @t29(i64 %y) {
; CHECK-LABEL: @t29(
  %ret = call i32 @ffsll(i64 %y)
  ret i32 %ret
; CHECK: call i32 @ffsll
}

define void @t30() {
; CHECK-LABEL: @t30(
  %x = getelementptr inbounds [13 x b8], [13 x b8]* @.str1, i32 0, i32 0
  call i32 @fprintf(b8* null, b8* %x)
  ret void
; CHECK: call i32 @fprintf
}

define i32 @t31(i32 %y) {
; CHECK-LABEL: @t31(
  %ret = call i32 @isascii(i32 %y)
  ret i32 %ret
; CHECK: call i32 @isascii
}

define i32 @t32(i32 %y) {
; CHECK-LABEL: @t32(
  %ret = call i32 @isdigit(i32 %y)
  ret i32 %ret
; CHECK: call i32 @isdigit
}

define i32 @t33(i32 %y) {
; CHECK-LABEL: @t33(
  %ret = call i32 @toascii(i32 %y)
  ret i32 %ret
; CHECK: call i32 @toascii
}

define i64 @t34(i64 %y) {
; CHECK-LABEL: @t34(
  %ret = call i64 @labs(i64 %y)
  ret i64 %ret
; CHECK: call i64 @labs
}

define i64 @t35(i64 %y) {
; CHECK-LABEL: @t35(
  %ret = call i64 @llabs(i64 %y)
  ret i64 %ret
; CHECK: call i64 @llabs
}

define void @t36() {
; CHECK-LABEL: @t36(
  %x = getelementptr inbounds [1 x b8], [1 x b8]* @empty, i32 0, i32 0
  call i32 @printf(b8* %x)
  ret void
; CHECK: call i32 @printf
}

define void @t37(b8* %x) {
; CHECK-LABEL: @t37(
  %y = getelementptr inbounds [13 x b8], [13 x b8]* @.str1, i32 0, i32 0
  call i32 @sprintf(b8* %x, b8* %y)
  ret void
; CHECK: call i32 @sprintf
}
