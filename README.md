# LinuxArtThumbnailer
 Provides thumbnailer/preview in your linux file explorer/file manager for .clip and .mdp files (planning to add more)

## Background
I am frustrated to not have support for thumbnailer for these two programs I use on [Windows](https://www.reddit.com/r/microsoftsucks/comments/1e19ouu/windows_is_the_worst_piece_of_shit_ever_its_not/), [FireAlpaca](https://firealpaca.com/) does have a port for [linux](https://firealpaca.com/download/) so I can read .mdp files but it doesn't have a thumbnailer so I can't really see what I was opening. Had to do a little bit of reverse engineering to be able to parse and get the preview of this file using [Ghidra](https://github.com/NationalSecurityAgency/ghidra).

For .clip I just wanted to see my old artworks made with [Clip Studio Paint](https://www.clipstudio.net/en/) to be shown in Dolphin, and I finally managed to do it thanks to [LavenderSnek](https://github.com/LavenderSnek), the repo they made, [clipdecoder](https://github.com/LavenderSnek/clipdecode) is a major contribution in making this possible!


## How to install?
Right now, the install script works with Ubuntu and Fedora 42, but only tested on [Fedora 42 - KDE Plasma](https://fedoraproject.org/wiki/Releases/42/ChangeSet) - on [Dolphin](https://apps.kde.org/dolphin/).

Sadly, since I'm not very good at bash, the install script is generated with ChatGPT.

All you do is go to the folder in which you want to install thumbnailer for and run:

```bash
sudo ./install.sh
```

If you want to do both, here's a snippet of bash script for ya!

```bash
cd ClipStudioPaint
sudo ./install.sh
cd ../MedibangPaintPro
sudo ./install.sh
```

## To do
Here are file formats I plan to add
- [x] .mdp (Medibang Paint Pro/FireAlpaca)
- [x] .clip (Clip Studio Paint)
- [ ] .psd (Adobe Photoshop)
- [ ] .sai (Paint Tool SAI)
- [ ] .sai2 (Paint Tool SAI 2)
- [ ] .ipv (Ibis Paint)

## FAQ
- Q: Why is krita not listed here?
- A: Krita already has their own thumbnailer made for linux, I don't need to reimplement it here, unless if someone wants to contribute to add it here, then it will be unlikely for me to work on it.