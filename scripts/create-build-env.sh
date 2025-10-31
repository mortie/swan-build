#!/bin/sh

set -ex

TOP="$PWD"
PFX="$TOP/pfx"

echo
echo "Preparing prefix..."
rm -rf "$PFX.work"
mkdir -p "$PFX.work"

echo
echo "Preparing submodules..."
git submodule update --init --recursive

echo
echo "Building LLVM..."
mkdir -p build/llvm && cd build/llvm
cmake -G Ninja \
	-DCMAKE_INSTALL_PREFIX="/usr" \
	-DCMAKE_INSTALL_LIBDIR="/usr/lib" \
	-DLIBCXX_INSTALL_LIBRARY_DIR="/usr/lib" \
	-DLIBCXXABI_INSTALL_LIBRARY_DIR="/usr/lib" \
	-DLIBUNWIND_INSTALL_LIBRARY_DIR="/usr/lib" \
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
DESTDIR="$PFX.work" ninja install
cd "$TOP"

export CC="$PFX.work/usr/bin/clang"
export CXX="$PFX.work/usr/bin/clang++"
export LDFLAGS="-L$PFX.work/usr/lib"

echo
echo "Building GLFW..."
mkdir -p build/glfw && cd build/glfw
cmake -G Ninja \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_INSTALL_PREFIX="/usr" \
	-DCMAKE_INSTALL_LIBDIR="/usr/lib" \
	-DGLFW_BUILD_TESTS=OFF \
	-DGLFW_BUILD_DOCS=OFF \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	"$TOP/common/glfw"
nice ninja
DESTDIR="$PFX.work" ninja install
cd "$TOP"

echo
echo "Building wxWidgets..."
mkdir -p build/wxWidgets && cd build/wxWidgets
cmake -G Ninja \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_INSTALL_PREFIX="/usr" \
	-DCMAKE_INSTALL_LIBDIR="/usr/lib" \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DwxUSE_USE_LIBPNG=builtin \
	"$TOP/common/wxWidgets"
nice ninja
DESTDIR="$PFX.work" ninja install
cd "$TOP"
ln -sf ../lib/wx/config/gtk3-unicode-3.3 "$PFX.work/usr/bin/wx-config"
ln -sf ./wxrc-3.3 "$PFX.work/usr/bin/wxrc"

echo
echo "Building capnproto..."
mkdir -p build/capnproto && cd build/capnproto
cmake -G Ninja \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_INSTALL_PREFIX="/usr" \
	-DCMAKE_INSTALL_LIBDIR="/usr/lib" \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	-DBUILD_TESTING=OFF \
	"$TOP/common/capnproto"
nice ninja
DESTDIR="$PFX.work" ninja install
cd "$TOP"

echo
echo "Patching capnproto..."
mv "$PFX.work/usr/bin/capnp" "$PFX.work/usr/bin/capnp.real"
cat >"$PFX.work/usr/bin/capnp" <<'EOF'
#!/bin/sh
"$(dirname "$0")/capnp.real" --no-standard-import -I"$CAPNP_SYSROOT" "$@"
EOF
chmod +x "$PFX.work/usr/bin/capnp"

echo
echo "Building portaudio..."
mkdir -p build/portaudio && cd build/portaudio
cmake -G Ninja \
	-DBUILD_SHARED_LIBS=ON \
	-DCMAKE_INSTALL_PREFIX="/usr" \
	-DCMAKE_INSTALL_LIBDIR="/usr/lib" \
	-DCMAKE_BUILD_TYPE=RelWithDebInfo \
	"$TOP/common/portaudio"
nice ninja
DESTDIR="$PFX.work" ninja install
cd "$TOP"

echo
echo "Building ffmpeg..."
mkdir -p build/ffmpeg && cd build/ffmpeg
"$TOP/common/ffmpeg/configure" \
	--prefix="/usr" \
	--libdir="/usr/lib" \
	--enable-pic \
	--disable-static \
	--enable-shared
nice make -j16
DESTDIR="$PFX.work" make install
cd "$TOP"

rm -rf "$PFX"
mv "$PFX.work" "$PFX"
