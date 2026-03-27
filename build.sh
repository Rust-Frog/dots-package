#!/bin/bash
# Build script for Caelestia local installation
# Creates tarballs that extract to ~/.local
set -euo pipefail

WORKSPACE="${1:-/workspace}"
cd "$WORKSPACE"

echo "=== Setting up pacman ==="
# Add Rust-Frog's quickshell repo (for build deps)
cat >> /etc/pacman.conf << 'EOF'

[quickshell]
SigLevel = Optional TrustAll
Server = https://rust-frog.github.io/quickshell/x86_64
EOF

# Initialize pacman keyring and update
pacman-key --init
pacman-key --populate archlinux
pacman -Syuu --noconfirm

echo "=== Installing build dependencies ==="
pacman -S --noconfirm --needed \
    base-devel \
    git \
    cmake \
    ninja \
    clang \
    pkg-config \
    python \
    python-pip \
    python-build \
    python-installer \
    python-hatchling \
    python-hatch-vcs \
    python-pillow \
    python-wheel \
    qt6-base \
    qt6-declarative \
    qt6-tools \
    libqalculate \
    pipewire \
    aubio \
    fftw \
    quickshell

# Build libcava from AUR (not in official repos)
echo "=== Building libcava from AUR ==="
useradd -m builder || true
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
cd /tmp
sudo -u builder bash << 'EOBUILD'
git clone https://aur.archlinux.org/libcava.git
cd libcava
makepkg -si --noconfirm
EOBUILD
cd "$WORKSPACE"

VERSION="${VERSION:-1.0.0}"
BUILD_DIR="/build"
INSTALL_ROOT="$BUILD_DIR/install-root"
CLI_INSTALL="$BUILD_DIR/cli-install"
SHELL_INSTALL="$BUILD_DIR/shell-install"

mkdir -p "$BUILD_DIR" "$INSTALL_ROOT" "$CLI_INSTALL" "$SHELL_INSTALL"
mkdir -p "$WORKSPACE/release"

# ============================================
# Build caelestia-cli
# ============================================
echo "=== Building caelestia-cli ==="
cd "$BUILD_DIR"
git clone https://github.com/Rust-Frog/cli.git caelestia-cli-src
cd caelestia-cli-src

# Get version from git
CLI_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")

# Build Python wheel
python -m build --wheel --no-isolation

# Install to temporary location
python -m installer --destdir="$CLI_INSTALL" dist/*.whl

# Reorganize to desired structure for ~/.local
mkdir -p "$CLI_INSTALL/.local/bin"
mkdir -p "$CLI_INSTALL/.local/share/caelestia"
mkdir -p "$CLI_INSTALL/.local/share/fish/vendor_completions.d"

# Find where pip installed things (usually usr/lib/python3.*/site-packages/caelestia)
PYTHON_SITE=$(find "$CLI_INSTALL" -type d -path "*/site-packages/caelestia" | head -1)
if [ -n "$PYTHON_SITE" ]; then
    # Copy Python package to share/caelestia
    cp -r "$PYTHON_SITE"/* "$CLI_INSTALL/.local/share/caelestia/"
    
    # Copy bin script if it exists
    if [ -f "$CLI_INSTALL/usr/bin/caelestia" ]; then
        cp "$CLI_INSTALL/usr/bin/caelestia" "$CLI_INSTALL/.local/bin/"
    fi
fi

# Copy completions
cp completions/caelestia.fish "$CLI_INSTALL/.local/share/fish/vendor_completions.d/"

# Create wrapper script if needed
cat > "$CLI_INSTALL/.local/bin/caelestia" << 'WRAPPER'
#!/usr/bin/env python3
import sys
import os

# Add ~/.local/share to Python path so 'caelestia' module is found
sys.path.insert(0, os.path.expanduser('~/.local/share'))

from caelestia import main

if __name__ == '__main__':
    main()
WRAPPER

chmod +x "$CLI_INSTALL/.local/bin/caelestia"

# Create tarball
cd "$CLI_INSTALL"
tar czf "$WORKSPACE/release/caelestia-cli-${CLI_VERSION}-local.tar.gz" .local/

# ============================================
# Build caelestia-shell
# ============================================
echo "=== Building caelestia-shell ==="
cd "$BUILD_DIR"
git clone https://github.com/Rust-Frog/CShell.git caelestia-shell-src
cd caelestia-shell-src

# Get version from git
SHELL_VERSION=$(git describe --tags --abbrev=0 2>/dev/null | sed 's/^v//' || echo "1.0.0")
GIT_REV=$(git rev-parse HEAD)

# Build with CMake - custom install paths for ~/.local
cmake -B build -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DCMAKE_INSTALL_PREFIX="$SHELL_INSTALL/.local" \
    -DVERSION="$SHELL_VERSION" \
    -DGIT_REVISION="$GIT_REV" \
    -DDISTRIBUTOR="Rust-Frog-Local" \
    -DINSTALL_QMLDIR=lib/qt6/qml \
    -DINSTALL_QSCONFDIR=etc/xdg/quickshell/caelestia \
    -DINSTALL_LIBDIR=lib/caelestia

cmake --build build

# Install to prefix
cmake --install build

# Fix permissions
chmod 755 "$SHELL_INSTALL/.local/etc/xdg/quickshell/caelestia/assets/"*.sh 2>/dev/null || true

# Create tarball
cd "$SHELL_INSTALL"
tar czf "$WORKSPACE/release/caelestia-shell-${SHELL_VERSION}-local.tar.gz" .local/

# ============================================
# Create checksums
# ============================================
echo "=== Creating checksums ==="
cd "$WORKSPACE/release"
sha256sum *.tar.gz > SHA256SUMS

echo "=== Release artifacts ==="
ls -lh "$WORKSPACE/release/"

echo "=== Build complete ==="
