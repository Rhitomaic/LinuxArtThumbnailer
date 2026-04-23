#!/usr/bin/env bash
set -e

# --- Configuration ---
THUMB_SCRIPT="mdp-thumbnailer"
THUMB_DESKTOP="mdp.thumbnailer"
MIME_XML="mdp.xml"

BIN_DIR="/usr/local/bin"
MIME_DIR="/usr/share/mime/packages"
THUMB_DIR="/usr/share/thumbnailers"

echo "🧩 Installing MediBang MDP thumbnailer..."

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
    echo "❌ Unsupported system: no pacman, dnf or apt found."
    exit 1
fi

# --- Install Python and pip if missing ---
if ! command -v python3 >/dev/null 2>&1; then
    echo "🐍 Installing Python 3..."
    case "$PKG_MANAGER" in
        pacman) pacman -Sy --noconfirm python ;;
        dnf)    dnf install -y python3 ;;
        apt)    apt update && apt install -y python3 ;;
    esac
fi

# --- Install Python dependencies ---
echo "📚 Installing required Python libraries (numpy, Pillow)..."
case "$PKG_MANAGER" in
    pacman)
        pacman -S --noconfirm python-numpy python-pillow
        ;;
    dnf)
        dnf install -y python3-numpy python3-pillow
        ;;
    apt)
        apt install -y python3-numpy python3-pil
        ;;
esac

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
# Running as root, we should target the actual user's cache if possible,
# but this keeps your original logic for the current user environment.
echo "🧹 Clearing thumbnail cache..."
rm -rf ~/.cache/thumbnails/* || true

echo ""
echo "✅ Installation complete!"
echo "Try running:"
echo "  mdp-thumbnailer input.mdp output.png"
