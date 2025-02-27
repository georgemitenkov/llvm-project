// RUN: mlir-opt %s -linalg-comprehensive-func-bufferize=test-analysis-only -split-input-file | FileCheck %s

//===----------------------------------------------------------------------===//
// Simple cases
//===----------------------------------------------------------------------===//

// -----

// CHECK-LABEL: func @extract_slice_fun
func @extract_slice_fun(%A : tensor<?xf32>, %B : tensor<?xf32> {linalg.inplaceable = true})
  -> (tensor<4xf32>, tensor<8xf32>)
{
  // tensor.extract_slice is not used in a write, it is not compelled to
  // bufferize out of place. Let callers decide whether they want to create
  // aliasing subviews at all call sites or whether they allocate.
  // This is true irrespective of whether the function argument is inplaceable.
  //     CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %r0 = tensor.extract_slice %A[0][4][1] : tensor<?xf32> to tensor<4xf32>

  //     CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %r1 = tensor.extract_slice %B[0][8][1] : tensor<?xf32> to tensor<8xf32>

  return %r0, %r1: tensor<4xf32>, tensor<8xf32>
}

// -----

// CHECK-LABEL: func @insert_slice_fun
func @insert_slice_fun(
    %A : tensor<?xf32>,
    %B : tensor<?xf32> {linalg.inplaceable = true},
    %C : tensor<4xf32>)
  -> (tensor<?xf32>, tensor<?xf32>)
{
  // must bufferize out of place.
  //     CHECK: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %r0 = tensor.insert_slice %C into %A[0][4][1] : tensor<4xf32> into tensor<?xf32>

  // bufferizes inplace.
  //     CHECK: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %r1 = tensor.insert_slice %C into %B[0][4][1] : tensor<4xf32> into tensor<?xf32>

  return %r0, %r1: tensor<?xf32>, tensor<?xf32>
}

// -----

// CHECK-LABEL: func @conflict_on_B
func @conflict_on_B(
    %A : tensor<4x4xf32> {linalg.inplaceable = true},
    %B : tensor<4x4xf32> {linalg.inplaceable = true})
  -> (tensor<4x4xf32>, tensor<4x4xf32>, tensor<4x4xf32>)
{
  // matmul output operand interferes with input operand.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %C = linalg.matmul  ins(%A, %B: tensor<4x4xf32>, tensor<4x4xf32>)
                     outs(%B: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  // matmul output operand interferes with input operand.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %D = linalg.matmul  ins(%B, %A: tensor<4x4xf32>, tensor<4x4xf32>)
                     outs(%B: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  // matmul output operand does not interferes with input operand.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %E = linalg.matmul  ins(%A, %A: tensor<4x4xf32>, tensor<4x4xf32>)
                     outs(%B: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  return %C, %D, %E: tensor<4x4xf32>, tensor<4x4xf32>, tensor<4x4xf32>
}

//===----------------------------------------------------------------------===//
// Length-1 producer-consumer cases.
//===----------------------------------------------------------------------===//

// -----

// CHECK-LABEL: func @extract_slice_extract_slice
func @extract_slice_extract_slice(
    %A : tensor<?xf32> {linalg.inplaceable = true}, %B : tensor<?xf32>)
  -> (tensor<2xf32>, tensor<2xf32>)
{
  // tensor.extract_slice is not used in a write, it is not compelled to
  // bufferize out of place. Let callers decide whether they want to create
  // aliasing subviews at all call sites or whether they allocate.
  // This is true irrespective of whether the function argument is inplaceable.
  // CHECK: {__inplace_results_attr__ = ["true"]}
  %r0 = tensor.extract_slice %A[0][4][1] : tensor<?xf32> to tensor<4xf32>

  // CHECK: {__inplace_results_attr__ = ["true"]}
  %r1 = tensor.extract_slice %r0[0][2][1] : tensor<4xf32> to tensor<2xf32>

  // CHECK: {__inplace_results_attr__ = ["true"]}
  %r2 = tensor.extract_slice %B[0][4][1] : tensor<?xf32> to tensor<4xf32>

  // CHECK: {__inplace_results_attr__ = ["true"]}
  %r3 = tensor.extract_slice %r2[0][2][1] : tensor<4xf32> to tensor<2xf32>

  return %r1, %r3: tensor<2xf32>, tensor<2xf32>
}

// -----

// CHECK-LABEL: func @insert_slice_insert_slice
func @insert_slice_insert_slice(
    %A : tensor<?xf32> {linalg.inplaceable = true},
    %A2 : tensor<4xf32> {linalg.inplaceable = true},
    %A3 : tensor<2xf32> {linalg.inplaceable = true},
    %B : tensor<?xf32>, %B2 : tensor<4xf32>, %B3 : tensor<2xf32>)
  -> (tensor<?xf32>, tensor<?xf32>)
{
  // CHECK: {__inplace_results_attr__ = ["true"]}
  %r0 = tensor.insert_slice %A3 into %A2[0][2][1] : tensor<2xf32> into tensor<4xf32>

  // CHECK: {__inplace_results_attr__ = ["true"]}
  %r1 = tensor.insert_slice %r0 into %A[0][4][1] : tensor<4xf32> into tensor<?xf32>

  // CHECK: {__inplace_results_attr__ = ["false"]}
  %r2 = tensor.insert_slice %B3 into %B2[0][2][1] : tensor<2xf32> into tensor<4xf32>

  // CHECK: {__inplace_results_attr__ = ["false"]}
  %r3 = tensor.insert_slice %r2 into %B[0][4][1] : tensor<4xf32> into tensor<?xf32>

  return %r1, %r3: tensor<?xf32>, tensor<?xf32>
}

// -----

// CHECK-LABEL: func @extract_slice_nonmatching_insert_slice
func @extract_slice_nonmatching_insert_slice(
    %A : tensor<?xf32> {linalg.inplaceable = true},
    %B : tensor<?xf32>, %idx: index)
  -> (tensor<?xf32>, tensor<?xf32>)
{
  // %r1 bufferizes inplace because %A is inplaceable.
  // %r0 is an overlapping tensor.extract_slice that does not match, it must be
  // out of place.
  //      CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %r0 = tensor.extract_slice %A[0][4][1] : tensor<?xf32> to tensor<4xf32>

  // %r1 can bufferize inplace fine.
  //      CHECK: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %r1 = tensor.insert_slice %r0 into %A[%idx][4][1] : tensor<4xf32> into tensor<?xf32>

  // %r3 does bufferizes inplace because %B is not inplaceable.
  // %r0 is an overlapping tensor.extract_slice that does not match, but does
  // not alias with the buffer coming from %r3 so it can actually bufferize
  // inplace.
  //      CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %r2 = tensor.extract_slice %B[0][4][1] : tensor<?xf32> to tensor<4xf32>

  // %r3 cannot bufferize inplace since %B is not inplaceable.
  //      CHECK: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %r3 = tensor.insert_slice %r2 into %B[%idx][4][1] : tensor<4xf32> into tensor<?xf32>

  return %r1, %r3: tensor<?xf32>, tensor<?xf32>
}

// -----

// CHECK-LABEL: func @extract_slice_matching_insert_slice
func @extract_slice_matching_insert_slice(
    %A : tensor<?xf32> {linalg.inplaceable = true},
    %B : tensor<?xf32>)
  -> (tensor<?xf32>, tensor<?xf32>)
{
  // %r1 bufferizes inplace because %A is inplaceable.
  // %r0 is a tensor.extract_slice that matches, it can also be bufferized
  // inplace.
  //      CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %r0 = tensor.extract_slice %A[0][4][1] : tensor<?xf32> to tensor<4xf32>

  //      CHECK: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %r1 = tensor.insert_slice %r0 into %A[0][4][1] : tensor<4xf32> into tensor<?xf32>

  // %r2 is a tensor.extract_slice that matches %r3, it can be bufferized
  // inplace.
  //      CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %r2 = tensor.extract_slice %B[0][4][1] : tensor<?xf32> to tensor<4xf32>

  // tensor.insert_slice cannot bufferize inplace.
  // This should have been captured by a canonicalization pattern and it would
  // be unproductive to have special logic in bufferization to encode matching
  // insert_slice(extract_slice(A), A).
  //      CHECK: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %r3 = tensor.insert_slice %r2 into %B[0][4][1] : tensor<4xf32> into tensor<?xf32>

  return %r1, %r3: tensor<?xf32>, tensor<?xf32>
}

// -----

// CHECK-LABEL: func @extract_slice_linalg_readonly_use
func @extract_slice_linalg_readonly_use(
    %A : tensor<?x?xf32>,
    %B : tensor<4x4xf32>,
    %C : tensor<4x4xf32> {linalg.inplaceable = true})
  ->  (tensor<4x4xf32>, tensor<4x4xf32>)
{
  // tensor.extract_slice is only used as a read, no interference irrespective
  // of user's inplace status.
  //     CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %sA = tensor.extract_slice %A[0, 0][4, 4][1, 1] : tensor<?x?xf32> to tensor<4x4xf32>

  // matmul output operand is not inplaceable at the function boundary.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %D = linalg.matmul  ins(%sA, %B: tensor<4x4xf32>, tensor<4x4xf32>)
                     outs(%B: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  // matmul output operand is inplaceable at the function boundary.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %E = linalg.matmul  ins(%sA, %B: tensor<4x4xf32>, tensor<4x4xf32>)
                     outs(%C: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  return %D, %E: tensor<4x4xf32>, tensor<4x4xf32>
}

// -----

// CHECK-LABEL: func @extract_slice_to_linalg_write_use
func @extract_slice_to_linalg_write_use(
    %A : tensor<4x4xf32>,
    %B : tensor<?x?xf32>,
    %C : tensor<?x?xf32> {linalg.inplaceable = true})
  ->  (tensor<4x4xf32>, tensor<4x4xf32>)
{
  // Step 3. %sB forward propagates to a write in %D but it is not inplace.
  // So this is only ever read and can bufferize inplace.
  //     CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %sB = tensor.extract_slice %B[0, 0][4, 4][1, 1] : tensor<?x?xf32> to tensor<4x4xf32>

  // Step 2. %sB has a read interference in %E, it does not bufferize inplace.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %D = linalg.matmul  ins(%B, %C: tensor<?x?xf32>, tensor<?x?xf32>)
                     outs(%sB: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  // Step 4. %sC forward propagates to an inplace write in %E.
  // %sC backward propagates to %C which is inplaceable.
  // As a consequence this is bufferized inplace.
  //     CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %sC = tensor.extract_slice %C[0, 0][4, 4][1, 1] : tensor<?x?xf32> to tensor<4x4xf32>

  // Step 1. %sC backprops to the tensor.extract_slice producer which is not
  // considered an interference. This bufferizes inplace.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %E = linalg.matmul  ins(%A, %sB: tensor<4x4xf32>, tensor<4x4xf32>)
                     outs(%sC: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  return %D, %E: tensor<4x4xf32>, tensor<4x4xf32>
}

//===----------------------------------------------------------------------===//
// Transitive cases
//===----------------------------------------------------------------------===//

// -----

// CHECK-LABEL: func @extract_slice_to_linalg_write_use
func @extract_slice_to_linalg_write_use(
    %A : tensor<4x4xf32>,
    %B : tensor<?x?xf32>,
    %C : tensor<?x?xf32> {linalg.inplaceable = true})
  ->  (tensor<4x4xf32>, tensor<4x4xf32>)
{
  // Step 4. %sB forward propagates to an inplace write in %D.
  // %sB backward propagates to %B which is not inplaceable.
  // As a consequence this is bufferized out of place.
  //     CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %sB = tensor.extract_slice %B[0, 0][4, 4][1, 1] : tensor<?x?xf32> to tensor<4x4xf32>

  // Step 1. %sB backprops to the tensor.extract_slice producer which is not
  // considered an interference. This bufferizes inplace.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %D = linalg.matmul  ins(%B, %C: tensor<?x?xf32>, tensor<?x?xf32>)
                     outs(%sB: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  // Step 3. %sC forward propagates to an inplace write in %E.
  // %sC backward propagates to %C which is inplaceable.
  // As a consequence this is bufferized inplace.
  //     CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %sC = tensor.extract_slice %C[0, 0][4, 4][1, 1] : tensor<?x?xf32> to tensor<4x4xf32>

  // Step 1. %sC backprops to the tensor.extract_slice producer which is not
  // considered an interference. This bufferizes inplace.
  //     CHECK: linalg.matmul
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %E = linalg.matmul  ins(%A, %A: tensor<4x4xf32>, tensor<4x4xf32>)
                     outs(%sC: tensor<4x4xf32>)
    -> tensor<4x4xf32>

  return %D, %E: tensor<4x4xf32>, tensor<4x4xf32>
}

// -----

// CHECK-LABEL: func @nested_extract_slice_and_insert
func @nested_extract_slice_and_insert(
    %A : tensor<?x?xf32>,
    %B : tensor<?x?xf32> {linalg.inplaceable = true},
    %C : tensor<?x?xf32> {linalg.inplaceable = true},
    %idx : index)
  ->  (tensor<?x?xf32>, tensor<?x?xf32>, tensor<?x?xf32>)
{
  %f0 = constant 0.0 : f32

  // 2-level matching tensor.extract_slice / tensor.insert_slice into non
  // inplaceable %A.
  //   - %rA is not inplaceable because %A is not inplaceable at function boundary.
  //   - once %rA is deemed not inplaceable, nothing prevent %rsA to be inplaceable
  //   - this propagates to %FA and %ssA being inplaceable.
  //   - %sA would then bufferize to an inplace write (i.e. %FA) but %A is not
  //     inplaceable and so %sA is not inplaceable.
  //     CHECK: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  // CHECK-NEXT: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: fill
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  %sA = tensor.extract_slice %A[0, 0][%idx, %idx][1, 1] : tensor<?x?xf32> to tensor<?x?xf32>
  %ssA = tensor.extract_slice %sA[0, 0][4, 4][1, 1] : tensor<?x?xf32> to tensor<4x4xf32>
  %FA = linalg.fill(%f0, %ssA) : f32, tensor<4x4xf32> -> tensor<4x4xf32>
  %rsA = tensor.insert_slice %FA into %sA[0, 0][4, 4][1, 1] : tensor<4x4xf32> into tensor<?x?xf32>
  %rA = tensor.insert_slice %rsA into %A[0, 0][%idx, %idx][1, 1] : tensor<?x?xf32> into tensor<?x?xf32>

  // 3-level matching tensor.extract_slice / tensor.insert_slice into
  // inplaceable %B.
  // CHECK-NEXT: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: tensor.extract_slice
  // Atm, this 2nd tensor.extract_slice fails to bufferize inplace because
  // clobbering analysis conservatively test for equivalent buffers.
  // TODO: This is currently too restrictive and misses clobberings.
  // When available, use container-containee analysis.
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  // CHECK-NEXT: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: fill
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %sB = tensor.extract_slice %B[0, 0][%idx, %idx][1, 1] : tensor<?x?xf32> to tensor<?x?xf32>
  %ssB = tensor.extract_slice %sB[0, 0][4, %idx][1, 1] : tensor<?x?xf32> to tensor<4x?xf32>
  %sssB = tensor.extract_slice %ssB[0, 0][4, 4][1, 1] : tensor<4x?xf32> to tensor<4x4xf32>
  %FB = linalg.fill(%f0, %sssB) : f32, tensor<4x4xf32> -> tensor<4x4xf32>
  %rssB = tensor.insert_slice %FB into %ssB[0, 0][4, 4][1, 1] : tensor<4x4xf32> into tensor<4x?xf32>
  %rsB = tensor.insert_slice %rssB into %sB[0, 0][4, %idx][1, 1] : tensor<4x?xf32> into tensor<?x?xf32>
  %rB = tensor.insert_slice %rsB into %B[0, 0][%idx, %idx][1, 1] : tensor<?x?xf32> into tensor<?x?xf32>

  // 2-level matching tensor.extract_slice / tensor.insert_slice into
  // inplaceable %C with a twist.
  // Throw a wrench in the system: %rsC production sizes do not match %ssC.
  // CHECK-NEXT: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // The tensor.insert_slice that would be candidate for matching does not actually
  // match. That tensor.insert_slice can still be bufferized inplace nonetheless
  // but this tensor.extract_slice, which bufferizes to an inplace write, cannot.
  // CHECK-NEXT: tensor.extract_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["false"]}
  // CHECK-NEXT: fill
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  // CHECK-NEXT: tensor.insert_slice
  // CHECK-SAME: {__inplace_results_attr__ = ["true"]}
  %sC = tensor.extract_slice %C[0, 0][%idx, %idx][1, 1] : tensor<?x?xf32> to tensor<?x?xf32>
  %ssC = tensor.extract_slice %sC[0, 0][4, 4][1, 1] : tensor<?x?xf32> to tensor<4x4xf32>
  %FC = linalg.fill(%f0, %ssC) : f32, tensor<4x4xf32> -> tensor<4x4xf32>
  %rsC = tensor.insert_slice %FC into %sC[0, 0][12345, 67890][1, 1] : tensor<4x4xf32> into tensor<?x?xf32>
  %rC = tensor.insert_slice %rsC into %C[0, 0][%idx, %idx][1, 1] : tensor<?x?xf32> into tensor<?x?xf32>

  return %rA, %rB, %rC: tensor<?x?xf32>, tensor<?x?xf32>, tensor<?x?xf32>
}

