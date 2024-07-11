#!/bin/sh
basename=`basename $1 | sed 's/[.][^.]*$//'`
# remove previously generated files
sh clean-out.sh $basename

# make an output directory if doesn't already exist
mkdir -p $basename/out

# lower mlir to llvm-mlir
#mlir-opt $basename/$basename.mlir  --one-shot-bufferize='bufferize-function-boundaries' -test-lower-to-llvm > $basename/out/$basename-in-llvm-dialect.mlir



# --------------------- Lowering MLIR to LLVM... ----------------------- V
mlir-opt --pass-pipeline='builtin.module(func.func(tosa-to-linalg-named, tosa-to-tensor, tosa-to-scf, tosa-to-linalg))' \
--mlir-print-op-generic --mlir-print-local-scope -o out/$basename.preproc1.mlir $basename/$basename.mlir

mlir-opt --tosa-to-arith="include-apply-rescale" --empty-tensor-to-alloc-tensor -o $basename/out/$basename.preproc2.0.mlir $basename/out/$basename.preproc1.mlir

# preproc2 to preproc3 with intermediate steps vvv
mlir-opt --test-linalg-transform-patterns="test-generalize-pad-tensor" \
-o $basename/out/$basename.preproc2.1.mlir $basename/out/$basename.preproc2.0.mlir

mlir-opt --linalg-generalize-named-ops \
-o $basename/out/$basename.preproc2.2.mlir $basename/out/$basename.preproc2.1.mlir

mlir-opt --empty-tensor-to-alloc-tensor \
-o $basename/out/$basename.preproc2.3.mlir $basename/out/$basename.preproc2.2.mlir

mlir-opt --one-shot-bufferize="bufferize-function-boundaries allow-return-allocs \
function-boundary-type-conversion=identity-layout-map" \
-o $basename/out/$basename.preproc2.4.mlir $basename/out/$basename.preproc2.3.mlir

mlir-opt --mlir-print-op-generic \
-o $basename/out/$basename.preproc2.5.mlir $basename/out/$basename.preproc2.4.mlir

mlir-opt --mlir-print-local-scope \
-o $basename/out/$basename.preproc3.mlir $basename/out/$basename.preproc2.5.mlir
# preproc2 to preproc3 with intermediate steps ^^^

cat $basename/out/$basename.preproc3.mlir | sed 's/arith.maxf/arith.maximumf/g' | sed 's/arith.minf/arith.minimumf/g' > $basename/out/$basename.preprocfinal.mlir

mlir-opt --mlir-print-op-generic \
-o $basename/out/$basename.preprocfinal.generic.mlir $basename/out/$basename.preprocfinal.mlir

# separating memory attotated IR from non-memory annotated IR
# /repo/runtime//../compiler/snax-opt -p dispatch-kernels,set-memory-space -o out/$basename.afterMemAnns.mlir out/$basename.preprocfinal.generic.mlir
# /repo/runtime//../compiler/snax-opt -p set-memory-layout,realize-memref-casts -o out/$basename.afterMemAnns2.mlir out/$basename.afterMemAnns.mlir
# /repo/runtime//../compiler/snax-opt -p \
# insert-sync-barrier,dispatch-regions,linalg-to-library-call,snax-copy-to-dma,memref-to-snax,snax-to-func,clear-memory-space \
# -o out/$basename.snax-opt.mlir out/$basename.afterMemAnns2.mlir

# fudge fudge fudge v v v
cat  $basename/out/$basename.preprocfinal.mlir > $basename/out/$basename.snax-opt.mlir
# fudge fudge fudge ^ ^ ^

cat $basename/out/$basename.snax-opt.mlir | sed 's/arith.maximumf/arith.maxf/g' | sed 's/arith.minimumf/arith.minf/g' > $basename/out/$basename.postproc.mlir

# TODO: Get rid of hard coding!
# THIS IS BAD HARDCODING THAT SHOULD BE REPLACED WITH AN XDSL PASS VVVVVVVVVVVVVVVV
# fill static_offset fields with zero values
# awk '/-9223372036854775808/ && ++count==2{sub(/-9223372036854775808/,"0")} 1' \
sed 's/-9223372036854775808/0/g' $basename/out/$basename.postproc.mlir > $basename/out/$basename.postproc.cleared.static.offsets.mlir
# fill offset fields with zero values
# awk '/offset: -156797324626531188736/ && ++count==2{sub(/offset: -156797324626531188736/,"offset: 0")} 1' \
sed 's/-156797324626531188736/0/g' $basename/out/$basename.postproc.cleared.static.offsets.mlir > $basename/out/$basename.postproc.cleared.offset.mlir
# THIS IS BAD HARDCODING THAT SHOULD BE REPLACED WITH AN XDSL PASS ^^^^^^^^^^^^^^^^

# mlir-opt --convert-linalg-to-loops --convert-scf-to-cf --lower-affine --canonicalize \
# --cse --convert-math-to-llvm --llvm-request-c-wrappers --expand-strided-metadata \
# --convert-index-to-llvm=index-bitwidth=32 --convert-cf-to-llvm=index-bitwidth=32 \
# --convert-arith-to-llvm=index-bitwidth=32 --convert-func-to-llvm='index-bitwidth=32' \
# --finalize-memref-to-llvm='use-generic-functions index-bitwidth=32' --canonicalize \
# --reconcile-unrealized-casts -o out/$basename.ll.mlir out/$basename.postproc.cleared.offset.mlir
# ^original^


mlir-opt  --convert-linalg-to-loops -o $basename/out/$basename.convert-linalg-to-loops.mlir $basename/out/$basename.postproc.cleared.offset.mlir
mlir-opt --convert-scf-to-cf -o $basename/out/$basename.convert-scf-to-cf.mlir $basename/out/$basename.convert-linalg-to-loops.mlir

# fold-memref-alias-ops
mlir-opt --fold-memref-alias-ops -o $basename/out/$basename.fold-memref-alias-ops.mlir $basename/out/$basename.convert-scf-to-cf.mlir
mlir-opt --lower-affine -o $basename/out/$basename.lower-affine.mlir $basename/out/$basename.fold-memref-alias-ops.mlir
# ^new^

# mlir-opt --lower-affine -o out/$basename.lower-affine.mlir out/$basename.convert-scf-to-cf.mlir
# ^old^
mlir-opt --canonicalize -o $basename/out/$basename.canonicalize.mlir $basename/out/$basename.lower-affine.mlir
mlir-opt --cse -o $basename/out/$basename.cse.mlir $basename/out/$basename.canonicalize.mlir
mlir-opt --convert-math-to-llvm -o $basename/out/$basename.convert-math-to-llvm.mlir $basename/out/$basename.cse.mlir
mlir-opt --llvm-request-c-wrappers --mlir-print-op-generic -o $basename/out/$basename.llvm-request-c-wrappers.mlir $basename/out/$basename.convert-math-to-llvm.mlir
mlir-opt --expand-strided-metadata -o $basename/out/$basename.expand-strided-metadata.mlir $basename/out/$basename.llvm-request-c-wrappers.mlir
mlir-opt --convert-index-to-llvm=index-bitwidth=32 -o $basename/out/$basename.convert-index-to-llvm32.mlir $basename/out/$basename.expand-strided-metadata.mlir
mlir-opt --convert-cf-to-llvm=index-bitwidth=32 -o $basename/out/$basename.convert-cf-to-llvm32.mlir $basename/out/$basename.convert-index-to-llvm32.mlir

mlir-opt --convert-arith-to-llvm=index-bitwidth=32 -o $basename/out/$basename.convert-arith-to-llvm32.mlir $basename/out/$basename.convert-cf-to-llvm32.mlir
mlir-opt --convert-func-to-llvm='index-bitwidth=32' -o $basename/out/$basename.convert-func-to-llvm32.mlir $basename/out/$basename.convert-arith-to-llvm32.mlir
# ^old^

#mlir-opt --convert-func-to-llvm='index-bitwidth=32' -o out/$basename.convert-func-to-llvm32.mlir out/$basename.convert-index-to-llvm32.mlir
# ^new^


mlir-opt --finalize-memref-to-llvm='use-generic-functions index-bitwidth=32' -o $basename/out/$basename.finalize-memref-to-llvm32.mlir $basename/out/$basename.convert-func-to-llvm32.mlir
# ^old^

mlir-opt --convert-arith-to-llvm=index-bitwidth=32 -o $basename/out/$basename.convert-arith-to-llvm32-2.mlir $basename/out/$basename.finalize-memref-to-llvm32.mlir
# ^new^

# mlir-opt --lower-affine -o out/$basename.lower-affine2.mlir out/$basename.finalize-memref-to-llvm32.mlir
# mlir-opt --canonicalize -o out/$basename.canonicalize2.mlir out/$basename.lower-affine2.mlir
# ^new^

# mlir-opt --canonicalize -o out/$basename.canonicalize2.mlir out/$basename.finalize-memref-to-llvm32.mlir
# ^old^

mlir-opt --canonicalize -o $basename/out/$basename.canonicalize2.mlir $basename/out/$basename.convert-arith-to-llvm32-2.mlir
# ^new^
mlir-opt --reconcile-unrealized-casts -o $basename/out/$basename.reconcile-unrealized-casts.mlir $basename/out/$basename.canonicalize2.mlir


mlir-translate --mlir-to-llvmir -o $basename/out/$basename.ll $basename/out/$basename.reconcile-unrealized-casts.mlir
#$basename/out/$basename.reconcile-unrealized-casts.mlir #out/$basename.ll.mlir

#/repo/runtime//tollvm12.py < out/$basename.ll > out/$basename.ll12

# --------------------- Lowering MLIR to LLVM... ----------------------- ^


