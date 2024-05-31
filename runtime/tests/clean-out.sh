basename=`basename $1 | sed 's/[.][^.]*$//'`
rm \
$basename/out/*.mlir \
$basename/out/*.o \
$basename/out/*.svg \
$basename/out/*.ll 
