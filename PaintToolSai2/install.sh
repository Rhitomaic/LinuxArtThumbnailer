#!/usr/bin/env bash
set -e

THUMB_SCRIPT="sai2-thumbnailer"
THUMB_DESKTOP="sai2.thumbnailer"
MIME_XML="sai2.xml"

BIN_DIR="/usr/local/bin"
MIME_DIR="/usr/share/mime/packages"
THUMB_DIR="/usr/share/thumbnailers"

echo "Installing Paint Tool SAI 2 thumbnailer..."

# need root, we install into /usr
if [[ $EUID -ne 0 ]]; then
    echo "Please run as root (e.g., sudo ./install.sh)"
    exit 1
fi

if command -v pacman >/dev/null 2>&1; then
    PKG_MANAGER="pacman"
elif command -v dnf >/dev/null 2>&1; then
    PKG_MANAGER="dnf"
elif command -v apt >/dev/null 2>&1; then
    PKG_MANAGER="apt"
else
    echo "Unsupported system: no pacman, dnf or apt found."
    exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
    echo "Installing Python 3..."
    case "$PKG_MANAGER" in
        pacman) pacman -Sy --noconfirm python ;;
        dnf)    dnf install -y python3 ;;
        apt)    apt update && apt install -y python3 ;;
    esac
fi

echo "Installing required Python libraries (numpy, Pillow)..."
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

if [[ -f "$THUMB_SCRIPT" ]]; then
    echo "Installing $THUMB_SCRIPT to $BIN_DIR"
    install -Dm755 "$THUMB_SCRIPT" "$BIN_DIR/$THUMB_SCRIPT"
else
    echo "$THUMB_SCRIPT not found!"
    exit 1
fi

if [[ -f "$MIME_XML" ]]; then
    echo "Installing $MIME_XML to $MIME_DIR"
    install -Dm644 "$MIME_XML" "$MIME_DIR/$MIME_XML"
else
    echo "No $MIME_XML found - skipping MIME registration"
fi

if [[ -f "$THUMB_DESKTOP" ]]; then
    echo "Installing $THUMB_DESKTOP to $THUMB_DIR"
    install -Dm644 "$THUMB_DESKTOP" "$THUMB_DIR/$THUMB_DESKTOP"
else
    echo "No $THUMB_DESKTOP found - skipping thumbnailer registration"
fi

echo "Updating MIME database..."
update-mime-database /usr/share/mime || true

if command -v update-desktop-database >/dev/null 2>&1; then
    echo "Updating desktop database..."
    update-desktop-database /usr/share/applications || true
fi

echo "Clearing thumbnail cache..."
# root runs this, so it clears root's cache and not the user's
rm -rf ~/.cache/thumbnails/* || true

echo ""
echo "Installation complete!"
echo "Try running:"
echo "  sai2-thumbnailer input.sai2 output.png"
