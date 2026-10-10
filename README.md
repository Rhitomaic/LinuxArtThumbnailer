# LinuxArtThumbnailer
 Provides thumbnailer/preview in your linux file explorer/file manager for .clip, .mdp and .sai2 files (planning to add more)

## Background
I am frustrated to not have support for thumbnailer for these two programs I use on [Windows](https://www.reddit.com/r/microsoftsucks/comments/1e19ouu/windows_is_the_worst_piece_of_shit_ever_its_not/) which are [FireAlpaca](https://firealpaca.com/) and [Clip Studio Paint](https://www.clipstudio.net/en/), I made this so that I can read `.mdp` files but it doesn't have a thumbnailer so I can't really see what I was opening. For `.clip` I just wanted to see my old artworks made with CSP to be shown in Dolphin, and I finally managed to do it.

### MediBang Paint/FireAlpaca .mdp support
FireAlpaca has a Linux port, which lets us read `.mdp` files. However, it doesn't provide thumbnails for file managers. This tool extracts the **embedded preview image** from `.mdp` files to generate thumbnails, without accessing the artwork layers or modifying the file.

### Clip Studio Paint .clip support
Thanks to [LavenderSnek's clipdecoder](https://github.com/LavenderSnek/clipdecode), it's possible to access the **embedded CanvasPreview** in `.clip` files. This project uses that data to generate thumbnails for Dolphin and other Linux file managers. Only the preview is read; no layers or proprietary artwork data is parsed.

### Paint Tool SAI 2 .sai2 support
`.sai2` files store a small **embedded preview** in their `thum` segment, encoded with a compact JPEG variant SAI calls `jssf`. This project decodes that embedded preview to generate thumbnails, without touching the artwork layers or modifying the file. Thanks to the community reverse-engineering work on the SAI2 container and the `jssf` codec (see [kagami-meika/sai2-thumbnail-provider](https://github.com/kagami-meika/sai2-thumbnail-provider) and [Wunkolo/libsai](https://github.com/Wunkolo/libsai)).

## Credit/Acknowledgements
Special thanks to [LavenderSnek](https://github.com/LavenderSnek) for their work on `.clip` decoding, which made thumbnail support possible.  

## Legal/Safe Use Disclaimer
This project **only reads embedded preview images** in `.mdp`, `.clip` and `.sai2` files. It does **not** reverse-engineer proprietary file formats, access full artwork layers, or modify the original files. Users must own the original software and files to be able to create and modify the file in the first place.

## How to install?
Right now, the install script works with Ubuntu, Fedora 42 and Arch Linux, though it's only been tested on [Fedora 42 - KDE Plasma](https://fedoraproject.org/wiki/Releases/42/ChangeSet) - on [Dolphin](https://apps.kde.org/dolphin/) - and on Arch Linux too.

Sadly, since I'm not very good at bash, the install script is generated with ChatGPT.

All you do is go to the folder in which you want to install thumbnailer for and run:

```bash
sudo ./install.sh
```

If you want to do all of them, here's a snippet of bash script for ya!

```bash
cd ClipStudioPaint
sudo ./install.sh
cd ../MedibangPaintPro
sudo ./install.sh
cd ../PaintToolSai2
sudo ./install.sh
```

## To do
Here are file formats I plan to add
- [x] .mdp (Medibang Paint Pro/FireAlpaca)
- [x] .clip (Clip Studio Paint)
- [ ] .sai (Paint Tool SAI)
- [x] .sai2 (Paint Tool SAI 2)
- [ ] .ipv (Ibis Paint)

## FAQ
- Q: Why is krita not listed here?
- A: Krita already has their own thumbnailer made for linux, I don't need to reimplement it here, unless if someone wants to contribute to add it here, then it will be unlikely for me to work on it.
