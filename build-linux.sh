#!/bin/sh

set -ex

SWAN="$1"
TOP="$PWD"

if [ -z "$SWAN" ]; then
	echo "Usage: $0 <swan>"
	exit 1
fi

echo
echo "Preparing prefix..."
PFX="$TOP/pfx.linux"
mkdir -p "$PFX.work"

echo
echo "Preparing submodules..."
git submodule update --init --recursive

echo
echo "Building LLVM..."
mkdir -p build.linux/llvm && cd build.linux/llvm
cmake -G Ninja \
	-DCMAKE_INSTALL_PREFIX="$PFX.work" \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DLLVM_ENABLE_PROJECTS="clang;lld" \
	-DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx;compiler-rt" \
	-DLLVM_PARALLEL_LINK_JOBS=2 \
	"$TOP/common/llvm-project/llvm"
nice ninja
ninja install
#ln -sf clang "$PFX.work/bin/clang++"
cd "$TOP"

echo
echo "Building wxWidgets..."
mkdir -p build.linux/wxWidgets && cd build.linux/wxWidgets
CC="$PFX.work/bin/clang" CXX="$PFX.work/bin/clang++" cmake -G Ninja \
	-DCMAKE_INSTALL_PREFIX="$PFX.work" \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	"$TOP/common/wxWidgets"
nice ninja
ninja install
cd "$TOP"

rm -rf "$PFX"
mv "$PFX.work" "$PFX"

echo "Building SWAN..."
mkdir -p build.linux
CC="$PFX/bin/clang" CXX="$PFX/bin/clang++" meson setup build.linux/swan \
	-Dprefix="$PFX" \
	"$SWAN"

cd build.linux/swan
nice ninja
ninja install
cd "$TOP"
