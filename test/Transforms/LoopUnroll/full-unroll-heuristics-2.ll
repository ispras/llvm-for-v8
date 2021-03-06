; RUN: opt < %s -S -loop-unroll -unroll-max-iteration-count-to-analyze=1000 -unroll-threshold=10  -unroll-percent-dynamic-cost-saved-threshold=50 -unroll-dynamic-cost-savings-discount=90 | FileCheck %s
target datalayout = "e-m:o-i64:64-f80:128-n8:16:32:64-S128"

; Though @unknown_global is initialized with constant values, we can't consider
; it as a constant, so we shouldn't unroll the loop.
; CHECK: %array_const_idx = getelementptr inbounds [9 x i32], [9 x i32]* @unknown_global, i64 0, i64 %iv
@unknown_global = internal unnamed_addr global [9 x i32] [i32 0, i32 -1, i32 0, i32 -1, i32 5, i32 -1, i32 0, i32 -1, i32 0], align 16

define i32 @foo(i32* noalias nocapture readonly %src) {
entry:
  br label %loop

loop:                                                ; preds = %loop, %entry
  %iv = phi i64 [ 0, %entry ], [ %inc, %loop ]
  %r  = phi i32 [ 0, %entry ], [ %add, %loop ]
  %arrayidx = getelementptr inbounds i32, i32* %src, i64 %iv
  %src_element = load i32, i32* %arrayidx, align 4
  %array_const_idx = getelementptr inbounds [9 x i32], [9 x i32]* @unknown_global, i64 0, i64 %iv
  %const_array_element = load i32, i32* %array_const_idx, align 4
  %mul = mul nsw i32 %src_element, %const_array_element
  %add = add nsw i32 %mul, %r
  %inc = add nuw nsw i64 %iv, 1
  %exitcond86.i = icmp eq i64 %inc, 9
  br i1 %exitcond86.i, label %loop.end, label %loop

loop.end:                                            ; preds = %loop
  %r.lcssa = phi i32 [ %r, %loop ]
  ret i32 %r.lcssa
}
