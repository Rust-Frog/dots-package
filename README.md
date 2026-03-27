# Caelestia Package Repository

Custom Arch Linux packages for [Caelestia dotfiles](https://github.com/Rust-Frog/dots) by Rust-Frog.

## 📦 Packages

| Package | Description | Source |
|---------|-------------|--------|
| `caelestia-cli` | CLI tool for wallpaper, color schemes, shell control | [Rust-Frog/cli](https://github.com/Rust-Frog/cli) |
| `caelestia-shell` | QML desktop shell with C++ plugin for Quickshell | [Rust-Frog/CShell](https://github.com/Rust-Frog/CShell) |

## 🚀 Usage

### Add the repository

Add to `/etc/pacman.conf`:

```ini
[caelestia]
SigLevel = Optional TrustAll
Server = https://rust-frog.github.io/dots-package/$arch
```

### Install packages

```bash
sudo pacman -Sy caelestia-cli caelestia-shell
```

### Full installation (with dotfiles)

```bash
# Clone the dotfiles repo
git clone https://github.com/Rust-Frog/dots.git
cd dots

# Run installer (will add repo and install packages automatically)
./install.fish
```

## 🔧 Dependencies

Make sure you have the Quickshell repository configured (for patched Quickshell):

```ini
[quickshell]
SigLevel = Optional TrustAll
Server = https://rust-frog.github.io/quickshell/x86_64
```

## 🏗️ Building

This repository uses GitHub Actions to automatically build packages daily and on push.

To build locally:

```bash
./build.sh
```

## 📋 Package Details

### caelestia-cli
- Python-based CLI tool
- Manages color schemes (Material You)
- Wallpaper management
- Shell control via IPC
- Screenshot and recording utilities

### caelestia-shell
- Built with Qt6/QML and C++
- Custom QML plugin with native integrations
- Quickshell-based desktop shell
- Includes bar, dashboard, launcher, notifications

## 🔄 CI/CD

- **Trigger**: Push to main, daily schedule (3 AM UTC), manual dispatch
- **Build**: Arch Linux container with all dependencies
- **Deploy**: GitHub Pages (gh-pages branch)
- **Auto-rebuild**: Can be triggered from cli/shell repos via repository_dispatch

## 📝 License

GPL-3.0-only (matching upstream Caelestia)
