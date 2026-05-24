#!/bin/sh
set -eu

cd "$(dirname "$0")/../zip"

built_products=""
for arch in ${ARCHS:-arm64}; do
  build_dir="../build/${arch}"
  rm -rf "${build_dir}"
  mkdir -p "${build_dir}"

  make -f unix/Makefile clean
  make -f unix/Makefile macosx_zip ARCH="${arch}"
  cp zip "${build_dir}"
  built_products="${built_products} ${build_dir}/zip"
done

lipo -create ${built_products} -output zip
cp LICENSE License-zip.txt

echo "Built zip"
