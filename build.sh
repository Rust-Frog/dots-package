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

# Build mpvpaper from AUR (for video wallpaper support)
echo "=== Building mpvpaper from AUR ==="
cd /tmp
sudo -u builder bash << 'EOBUILD'
git clone https://aur.archlinux.org/mpvpaper.git
cd mpvpaper
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
# Download and package emoji font
# ============================================
echo "=== Packaging fonts (Emoji + Material Symbols + Rubik) ==="
FONT_INSTALL="$BUILD_DIR/font-install"
mkdir -p "$FONT_INSTALL/.local/share/fonts"
mkdir -p "$FONT_INSTALL/.config/fontconfig"

cd /tmp

# Download Noto Color Emoji
echo "Downloading Noto Color Emoji..."
curl -L -o NotoColorEmoji.ttf "https://github.com/googlefonts/noto-emoji/raw/main/fonts/NotoColorEmoji.ttf"
cp NotoColorEmoji.ttf "$FONT_INSTALL/.local/share/fonts/"

# Download Material Symbols (Google Fonts variable version)
echo "Downloading Material Symbols..."
curl -L -o MaterialSymbols.zip "https://github.com/google/material-symbols/archive/refs/heads/main.zip"
unzip -o -j MaterialSymbols.zip "material-symbols-main/fonts/variable/MaterialSymbols*.ttf" -d "$FONT_INSTALL/.local/share/fonts/" 2>/dev/null || true

# Download Rubik font (static version)
echo "Downloading Rubik font..."
curl -L -o Rubik.zip "https://github.com/googlefonts/rubik/archive/refs/heads/main.zip"
unzip -o -j Rubik.zip "rubik-main/fonts/ttf/Rubik-*.ttf" -d "$FONT_INSTALL/.local/share/fonts/" 2>/dev/null || true

# Clean up temp files
rm -f NotoColorEmoji.ttf MaterialSymbols.zip Rubik.zip

# Create fontconfig to prefer emoji and fallback fonts
cat > "$FONT_INSTALL/.config/fontconfig/fonts.conf" << 'FONTCONFIG'
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
  <!-- Emoji font -->
  <alias>
    <family>sans-serif</family>
    <prefer>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>
  <alias>
    <family>serif</family>
    <prefer>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>
  <alias>
    <family>monospace</family>
    <prefer>
      <family>Noto Color Emoji</family>
    </prefer>
  </alias>

  <!-- Material Symbols for icons -->
  <alias>
    <family>Material Symbols</family>
    <family>Material Symbols Rounded</family>
    <family>Material Symbols Sharp</family>
    <default>
      <family>Material Symbols Rounded</family>
    </default>
  </alias>

  <!-- Rubik for text -->
  <alias>
    <family>Rubik</family>
    <default>
      <family>Rubik</family>
    </default>
  </alias>
</fontconfig>
FONTCONFIG

# Create tarball
cd "$FONT_INSTALL"
tar czf "$WORKSPACE/release/caelestia-fonts-${VERSION}-local.tar.gz" .local/ .config/

# Create latest symlink for easy access
cd "$WORKSPACE/release"
ln -sf "caelestia-fonts-${VERSION}-local.tar.gz" caelestia-fonts-latest.tar.gz

# ============================================
# Create checksums
# ============================================
echo "=== Creating checksums ==="
cd "$WORKSPACE/release"
sha256sum *.tar.gz > SHA256SUMS

echo "=== Release artifacts ==="
ls -lh "$WORKSPACE/release/"

echo "=== Build complete ==="
