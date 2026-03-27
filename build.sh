#!/bin/bash
# Build script for Caelestia packages
# Runs inside Arch Linux container
set -euo pipefail

WORKSPACE="${1:-/workspace}"
cd "$WORKSPACE"

echo "=== Setting up pacman ==="
# Add Rust-Frog's quickshell repo (patched version)
cat >> /etc/pacman.conf << 'EOF'

[quickshell]
SigLevel = Optional TrustAll
Server = https://rust-frog.github.io/quickshell/x86_64
EOF

# Initialize pacman keyring and update
pacman-key --init
pacman-key --populate archlinux
pacman -Syuu --noconfirm

echo "=== Installing base build dependencies ==="
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
    libcava \
    fftw \
    quickshell

# Create build user (makepkg can't run as root)
useradd -m builder || true
echo "builder ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Ensure workspace is accessible
chown -R builder:builder "$WORKSPACE"

echo "=== Building caelestia-cli ==="
cd "$WORKSPACE/caelestia-cli"
sudo -u builder makepkg -sf --noconfirm

echo "=== Building caelestia-shell ==="
cd "$WORKSPACE/caelestia-shell"
sudo -u builder makepkg -sf --noconfirm

echo "=== Creating pacman repository ==="
mkdir -p "$WORKSPACE/public/x86_64"

# Copy built packages
cp "$WORKSPACE/caelestia-cli/"*.pkg.tar.zst "$WORKSPACE/public/x86_64/"
cp "$WORKSPACE/caelestia-shell/"*.pkg.tar.zst "$WORKSPACE/public/x86_64/"

# Create repo database
cd "$WORKSPACE/public/x86_64"
repo-add caelestia.db.tar.gz *.pkg.tar.zst

# Create symlinks for repo-add output
ln -sf caelestia.db.tar.gz caelestia.db
ln -sf caelestia.files.tar.gz caelestia.files

echo "=== Repository contents ==="
ls -lh "$WORKSPACE/public/x86_64/"

echo "=== Build complete ==="
