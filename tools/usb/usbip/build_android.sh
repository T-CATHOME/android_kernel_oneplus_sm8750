#!/bin/sh
# SPDX-License-Identifier: GPL-2.0

set -eu

ROOT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OUT_DIR="${OUT_DIR:-$ROOT_DIR/out}"
BUILD_DIR="$OUT_DIR/build"
INSTALL_DIR="$OUT_DIR/install"
NDK_ROOT="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
TOOLCHAIN_DIR=""

require_cmd() {
	if ! command -v "$1" >/dev/null 2>&1; then
		echo "error: missing required command: $1" >&2
		exit 1
	fi
}

require_pkgconfig_lib() {
	if ! command -v pkg-config >/dev/null 2>&1; then
		echo "error: missing required command: pkg-config" >&2
		exit 1
	fi
	if ! pkg-config --exists "$1"; then
		echo "error: missing required pkg-config package: $1" >&2
		exit 1
	fi
}

require_file() {
	if [ ! -f "$1" ]; then
		echo "error: missing required file: $1" >&2
		exit 1
	fi
}

require_cmd autoreconf
require_cmd automake
require_cmd autoconf
require_cmd make
require_cmd pkg-config
require_pkgconfig_lib libudev

if [ -z "$NDK_ROOT" ]; then
	echo "error: set ANDROID_NDK_HOME (or ANDROID_NDK_ROOT) to an Android NDK path" >&2
	exit 1
fi

TOOLCHAIN_DIR="$NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin"
require_file "$TOOLCHAIN_DIR/clang"
require_file "$TOOLCHAIN_DIR/llvm-ar"
require_file "$TOOLCHAIN_DIR/llvm-ranlib"

mkdir -p "$BUILD_DIR" "$INSTALL_DIR"

cd "$ROOT_DIR"
autoreconf -i -f

cd "$BUILD_DIR"
export CC="$TOOLCHAIN_DIR/clang"
export AR="$TOOLCHAIN_DIR/llvm-ar"
export RANLIB="$TOOLCHAIN_DIR/llvm-ranlib"
"$ROOT_DIR/configure" \
	--disable-silent-rules \
	--without-tcp-wrappers \
	--prefix="$INSTALL_DIR"
make -j"$(getconf _NPROCESSORS_ONLN)"
make install

echo "usbip userspace tools built successfully."
echo "toolchain: $TOOLCHAIN_DIR"
echo "binaries:"
echo "  $INSTALL_DIR/sbin/usbip"
echo "  $INSTALL_DIR/sbin/usbipd"
