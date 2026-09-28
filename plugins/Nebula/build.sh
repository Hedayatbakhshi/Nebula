#!/bin/bash
set -e
cd "$(dirname "$0")"

echo "==> Building Nebula QML plugin..."
mkdir -p build && cd build

_CXX=$(command -v g++ 2>/dev/null || command -v clang++ 2>/dev/null || true)
if [[ -z "$_CXX" ]]; then
  echo "ERROR: no C++ compiler found (g++ or clang++)" >&2; exit 1
fi

cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_COMPILER="$_CXX"
cmake --build . -j"$(nproc)"

dest="$HOME/.local/lib/qt6/qml/Nebula"
stage="$(mktemp -d)"
trap 'rm -rf "$stage"' EXIT
cmake --install . --prefix "$stage" >/dev/null

echo "==> Installing to $dest ..."
mkdir -p "$dest"
for f in "$stage/Nebula/"*; do
  name="$(basename "$f")"
  cp -f "$f" "$dest/.$name.new"
  mv -f "$dest/.$name.new" "$dest/$name"
done

echo "==> Done. Restart Quickshell to pick up a changed plugin."
