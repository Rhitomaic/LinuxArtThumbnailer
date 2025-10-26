#!/usr/bin/env bash
set -e

# --- Configuration ---
THUMB_SCRIPT="clip-thumbnailer"
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
if command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
elif command -v apt >/dev/null 2>&1; then
    PKG_MANAGER="apt"
else
    echo "❌ Unsupported system: no dnf or apt found."
    exit 1
fi

# --- Install Python and pip if missing ---
if ! command -v python3 >/dev/null 2>&1; then
    echo "🐍 Installing Python 3..."
    if [ "$PKG_MANAGER" = "dnf" ]; then
        dnf install -y python3
    else
        apt update && apt install -y python3
    fi
fi

# --- Install Python dependencies ---
echo "📚 Installing required Python libraries (numpy, Pillow)..."
if [ "$PKG_MANAGER" = "dnf" ]; then
    dnf install -y python3-numpy python3-pillow
else
    apt install -y python3-numpy python3-pil
fi

# --- Install the thumbnailer script ---
if [[ -f "$THUMB_SCRIPT" ]]; then
    echo "📦 Installing $THUMB_SCRIPT → $BIN_DIR"
    install -Dm755 "$THUMB_SCRIPT" "$BIN_DIR/$THUMB_SCRIPT"
else
    echo "❌ $THUMB_SCRIPT not found!"
    exit 1
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
echo "Try running:"
echo "  clip-thumbnailer input.clip output.png"
echo ""
echo "If Dolphin or Nautilus doesn't show thumbnails yet, enable it in the preferences, or restart it or log out."
