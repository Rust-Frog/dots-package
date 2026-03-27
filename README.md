# Caelestia Local Installation Packages

Pre-built packages for **local installation** to `~/.local` by Rust-Frog.

**No sudo required. User-specific installation.**

## 📦 Packages

| Package | Description | Key Files |
|---------|-------------|-----------|
| `caelestia-cli` | CLI tool for wallpaper, color schemes, shell control | `~/.local/bin/caelestia`, `~/.local/share/caelestia/` |
| `caelestia-shell` | QML desktop shell with C++ plugin for Quickshell | `~/.local/etc/xdg/quickshell/caelestia/`, `~/.local/lib/qt6/qml/Caelestia/` |

## 🚀 Quick Start

### Automatic Installation (Recommended)

```bash
# Clone the dotfiles repo
git clone https://github.com/Rust-Frog/dots.git
cd dots

# Run installer (downloads and extracts to ~/.local)
./install.fish
```

### Manual Installation

```bash
# Download and extract to home directory (creates ~/.local structure)
cd ~
curl -sL https://rust-frog.github.io/dots-package/caelestia-cli-latest.tar.gz | tar xz
curl -sL https://rust-frog.github.io/dots-package/caelestia-shell-latest.tar.gz | tar xz

# Add ~/.local/bin to PATH
fish_add_path ~/.local/bin  # for fish shell
# or add to ~/.bashrc or ~/.zshrc:
export PATH="$HOME/.local/bin:$PATH"

# Symlink shell config for Quickshell
ln -s ~/.local/etc/xdg/quickshell/caelestia ~/.config/quickshell/caelestia
```

## 📂 Installation Layout

After installation, your `~/.local` will contain:

```
~/.local/
├── bin/
│   └── caelestia                           # CLI command
├── etc/
│   └── xdg/
│       └── quickshell/
│           └── caelestia/                  # Shell QML files, assets, configs
│               ├── shell.qml
│               ├── components/
│               ├── services/
│               ├── modules/
│               └── assets/
├── lib/
│   ├── caelestia/                          # Shell extras (version binary, etc.)
│   └── qt6/
│       ├── qml/
│       │   └── Caelestia/                  # QML C++ plugin
│       └── plugins/                        # Qt plugins
└── share/
    ├── caelestia/                          # CLI Python package
    └── fish/
        └── vendor_completions.d/           # Fish completions
```

Symlink created by installer:
```
~/.config/quickshell/caelestia -> ~/.local/etc/xdg/quickshell/caelestia
```

## 🔧 Dependencies

### Runtime Dependencies (install via pacman)

**Essential:**
```bash
# Quickshell (from Rust-Frog repo)
sudo pacman -S quickshell

# Qt6
sudo pacman -S qt6-base qt6-declarative

# Python
sudo pacman -S python python-pillow python-materialyoucolor
```

**Shell Dependencies:**
```bash
sudo pacman -S libqalculate pipewire aubio libcava fftw \
    fish brightnessctl ddcutil networkmanager lm_sensors \
    swappy wl-clipboard hyprland
```

### Quickshell Repository

Add to `/etc/pacman.conf`:
```ini
[quickshell]
SigLevel = Optional TrustAll
Server = https://rust-frog.github.io/quickshell/x86_64
```

Then: `sudo pacman -Sy quickshell`

## 🏗️ Building

This repository uses GitHub Actions to automatically build packages daily.

**Build Process:**
1. Arch Linux container with all dependencies
2. Build CLI (Python wheel) and Shell (CMake)
3. Install to custom prefix with proper `~/.local` structure
4. Create tarballs with `local/` directory at root
5. Deploy to GitHub Pages

To build locally:
```bash
./build.sh
```

## 🔄 Updates

Packages auto-build daily at 3 AM UTC. To update:

```bash
# Option 1: Re-run install.fish
cd ~/dots
./install.fish

# Option 2: Manual update
cd ~
curl -sL https://rust-frog.github.io/dots-package/caelestia-cli-latest.tar.gz | tar xz
curl -sL https://rust-frog.github.io/dots-package/caelestia-shell-latest.tar.gz | tar xz
```

## 🆚 Comparison: System-Wide vs Local

| Aspect | System-Wide (/usr) | Local (~/.local) ✅ |
|--------|--------------------|---------------------|
| Sudo required | ✅ Yes | ❌ **No** |
| Affects other users | ✅ Yes | ❌ **No (isolated)** |
| Package manager | Pacman | Manual |
| Easy updates | `pacman -Syu` | Re-run installer |
| Portable | ❌ | ✅ **Backup ~/.local** |
| Custom patches | Rebuild | **Just extract** |

## 📋 CI/CD Pipeline

| Trigger | Frequency |
|---------|-----------|
| Push to main | Immediate |
| Daily schedule | 3 AM UTC |
| Manual dispatch | On-demand |
| Repository dispatch | From cli/shell repos |

**Artifacts:** Versioned tarballs + "latest" symlinks + SHA256SUMS

**Deployment:** GitHub Pages at `https://rust-frog.github.io/dots-package/`

## 🔗 Links

- **[Dotfiles](https://github.com/Rust-Frog/dots)** - Main installation repo
- **[CLI Source](https://github.com/Rust-Frog/cli)** - Python CLI
- **[Shell Source](https://github.com/Rust-Frog/CShell)** - QML shell + C++ plugin
- **[Quickshell Fork](https://github.com/Rust-Frog/quickshell)** - Patched runtime

## 🐛 Troubleshooting

### CLI command not found
```bash
# Ensure ~/.local/bin is in PATH
export PATH="$HOME/.local/bin:$PATH"

# Check if file exists
ls -la ~/.local/bin/caelestia
```

### Shell not loading
```bash
# Check symlink
ls -la ~/.config/quickshell/caelestia

# Should point to: ~/.local/etc/xdg/quickshell/caelestia

# Recreate if needed
ln -sf ~/.local/etc/xdg/quickshell/caelestia ~/.config/quickshell/caelestia
```

### QML plugin not found
```bash
# Check environment in ~/.config/fish/config.fish
set -gx QML_IMPORT_PATH "$HOME/.local/lib/qt6/qml" $QML_IMPORT_PATH
```

## 📝 License

GPL-3.0-only (matching upstream Caelestia)

---