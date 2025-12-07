#!/bin/sh

set -ex

TOP="$PWD"
PFX="$TOP/pfx"

echo
echo "Preparing prefix..."
rm -rf "$PFX"
mkdir -p "$PFX"

echo
echo "Preparing submodules..."
git submodule update --init --recursive

# LLVM needs a fairly modern CMake,
# we need to compile on fairly old Linux distros
# to link against an old enough glibc ABI :(
echo
echo "Building CMake..."
mkdir -p build/cmake && cd build/cmake
"$TOP/common/cmake/bootstrap" \
	--prefix="$PFX" \
	--parallel=$(nproc) \
	--generator=Ninja
nice ninja
ninja install
cd "$TOP"

export PATH="$PFX/bin:$PATH"

echo
echo "Building LLVM..."
mkdir -p build/llvm && cd build/llvm
cmake -G Ninja \
	-DCMAKE_INSTALL_PREFIX="$PFX" \
	-DCMAKE_INSTALL_LIBDIR="$PFX/lib" \
	-DLIBCXX_INSTALL_LIBRARY_DIR="$PFX/lib" \
	-DLIBCXXABI_INSTALL_LIBRARY_DIR="$PFX/lib" \
	-DLIBUNWIND_INSTALL_LIBRARY_DIR="$PFX/lib" \
	-DCLANG_CONFIG_FILE_SYSTEM_DIR="../lib/clang" \
	-DCLANG_CONFIG_FILE_USER_DIR="../lib/clang" \
	-DCMAKE_BUILD_TYPE=Release \
	-DLLVM_ENABLE_PROJECTS="clang;lld" \
	-DLLVM_ENABLE_RUNTIMES="libunwind;libcxxabi;libcxx;compiler-rt" \
	-DLLVM_INSTALL_TOOLCHAIN_ONLY=ON \
	-DLLVM_INCLUDE_TESTS=OFF \
	-DLLVM_INCLUDE_BENCHMARKS=OFF \
	-DLLVM_INCLUDE_EXAMPLES=OFF \
	-DLLVM_INCLUDE_DOCS=OFF \
	-DCLANG_INCLUDE_TESTS=OFF \
	-DCLANG_INCLUDE_DOCS=OFF \
	-DLLVM_PARALLEL_LINK_JOBS=2 \
	-DLLVM_BUILD_STATIC=OFF \
	-DLLVM_BUILD_LLVM_DYLIB=ON \
	-DLLVM_LINK_LLVM_DYLIB=ON \
	-DCLANG_DEFAULT_CXX_STDLIB=libc++ \
	-DCLANG_DEFAULT_RTLIB=compiler-rt \
	-DCLANG_DEFAULT_LINKER=lld \
	-DCLANG_DEFAULT_UNWINDLIB=libunwind \
	"$TOP/common/llvm/llvm"
nice ninja clang lld
ninja install
cd "$TOP"

export CC="$PFX/bin/clang"
export CXX="$PFX/bin/clang++"
export LDFLAGS="-L$PFX/lib"

echo
echo "Building ffmpeg..."
mkdir -p build/ffmpeg && cd build/ffmpeg
"$TOP/common/ffmpeg/configure" \
	--prefix="$PFX" \
	--libdir="$PFX/lib" \
	--enable-pic \
	--disable-static \
	--enable-shared
nice make -j16
make install
cd "$TOP"
