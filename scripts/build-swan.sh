#!/bin/sh

set -ex

TOP="$PWD"
PFX="$TOP/pfx"

SWAN="$1"

if [ -z "$SWAN" ]; then
	echo "Usage: $0 <swan>"
	exit 1
fi

export CC="$PFX/usr/bin/clang"
export CXX="$PFX/usr/bin/clang++"
export PKG_CONFIG_PATH="$PFX/usr/lib/pkgconfig"
export PKG_CONFIG_SYSROOT_DIR="$PFX"
export LD_LIBRARY_PATH="$PFX/usr/lib"
export LDFLAGS="-L$PFX/usr/lib"
export PATH="$PFX/usr/bin:$PATH"
export CAPNP_SYSROOT="$PFX/usr/include"

echo "Building SWAN..."
mkdir -p build
rm -rf build/swan
./common/meson/meson.py setup \
	-Dprefix="$PFX" \
	build/swan \
	"$SWAN"
cd build/swan
nice ninja
ninja install
cd "$TOP"
