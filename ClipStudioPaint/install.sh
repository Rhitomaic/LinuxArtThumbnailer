#!/usr/bin/env bash
set -e

# --- Configuration ---
THUMB_DESKTOP="clip.thumbnailer"
MIME_XML="clip.xml"

BIN_DIR="/usr/local/bin"
MIME_DIR="/usr/share/mime/packages"
THUMB_DIR="/usr/share/thumbnailers"

echo "🖌 Installing Clip Studio Paint thumbnailer..."

# --- Require root privileges ---
if [[ $EUID -ne 0 ]]; then
    echo "❌ Please run as root (e.g., sudo ./install.sh)"
    exit 1
fi

# --- Detect package manager ---
if command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
elif command -v apt >/dev/null 2>&1; then
    PKG_MANAGER="apt"
else
    echo "❌ Unsupported system: no pacman, dnf, or apt found."
    exit 1
fi

# --- Check for Rust and build optimized version ---
if command -v cargo >/dev/null 2>&1; then
    echo "🦀 Rust detected! Building optimized native binary..."
    
    # Build release binary (as non-root user if using sudo)
    if [ -n "$SUDO_USER" ]; then
        su - "$SUDO_USER" -c "cd '$PWD' && cargo build --release" || {
            echo "⚠️  Rust build failed, falling back to Python version"
            USE_RUST=0
        }
    else
        cargo build --release || {
            echo "⚠️  Rust build failed, falling back to Python version"
            USE_RUST=0
        }
    fi
    
    if [ -f "target/release/clip-thumbnailer-rs" ]; then
        echo "📦 Installing Rust binary → $BIN_DIR/clip-thumbnailer"
        install -Dm755 "target/release/clip-thumbnailer-rs" "$BIN_DIR/clip-thumbnailer"
        USE_RUST=1
    fi
else
    echo "⚠️  Rust not found. Install with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    echo "📝 Falling back to Python version (slower but works)"
    USE_RUST=0
fi

# --- Install Python version as fallback ---
if [ "$USE_RUST" != "1" ]; then
    # Install Python if missing
    if ! command -v python3 >/dev/null 2>&1; then
        echo "🐍 Installing Python 3..."
        if [ "$PKG_MANAGER" = "pacman" ]; then
            pacman -S --noconfirm python
        elif [ "$PKG_MANAGER" = "dnf" ]; then
            dnf install -y python3
        else
            apt update && apt install -y python3
        fi
    fi
    
    if [[ -f "clip-thumbnailer.py" ]]; then
        echo "📦 Installing Python script → $BIN_DIR/clip-thumbnailer"
        install -Dm755 "clip-thumbnailer.py" "$BIN_DIR/clip-thumbnailer"
    else
        echo "❌ clip-thumbnailer.py script not found!"
        exit 1
    fi
fi

# --- Install MIME type XML ---
if [[ -f "$MIME_XML" ]]; then
    echo "📦 Installing $MIME_XML → $MIME_DIR"
    install -Dm644 "$MIME_XML" "$MIME_DIR/$MIME_XML"
else
    echo "⚠️  No $MIME_XML found — skipping MIME registration"
fi

# --- Install thumbnailer descriptor ---
if [[ -f "$THUMB_DESKTOP" ]]; then
    echo "📦 Installing $THUMB_DESKTOP → $THUMB_DIR"
    install -Dm644 "$THUMB_DESKTOP" "$THUMB_DIR/$THUMB_DESKTOP"
else
    echo "⚠️  No $THUMB_DESKTOP found — skipping thumbnailer registration"
fi

# --- Update system MIME database ---
echo "🔄 Updating MIME database..."
update-mime-database /usr/share/mime || true

# --- Update desktop thumbnailers ---
if command -v update-desktop-database >/dev/null 2>&1; then
    echo "🔄 Updating desktop database..."
    update-desktop-database /usr/share/applications || true
fi

# --- Clear cache ---
echo "🧹 Clearing thumbnail cache..."
rm -rf ~/.cache/thumbnails/* || true

echo ""
echo "✅ Installation complete!"
if [ "$USE_RUST" = "1" ]; then
    echo "🦀 Using high-performance Rust implementation (10x+ faster)"
else
    echo "🐍 Using Python implementation (consider installing Rust for 10x+ speedup)"
fi
echo ""
echo "Try running:"
echo "  clip-thumbnailer input.clip output.png"
echo ""
echo "⚠️  For large files (>500MB): Increase Dolphin's file size limit"
echo "   Edit ~/.config/dolphinrc under [PreviewSettings]:"
echo "   MaximumSize=2147483648  # 2GB limit"
echo ""
echo "If Dolphin or Nautilus doesn't show thumbnails yet, enable it in the preferences, or restart it or log out."
