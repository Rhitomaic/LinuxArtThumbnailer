# PR: High-Performance Rust Thumbnailer for Clip Studio Paint (.clip files)

## Summary

Hi this pr is a Rust rewrite of the **Clip Studio Paint thumbnailer only** with 4x-91x performance improvement over the original Python implementation.

I prioritized Clip Studio Paint because I actively use it for my artwork, and the original Python implementation became unusably slow with my large project files (500MB-1GB+) and large directories.

**Scope:** This PR only affects `ClipStudioPaint/` directory. MedibangPaintPro thumbnailer is unchanged and can be optimized in a future PR if desired.

**Testing environment:** CachyOS with KDE Plasma 6 / Dolphin file manager

## Benchmarks at a glance

Comparing commit 6d36a31 vs this implementation tested at different file sizes:

| File Size | Original Python | Rust | Speedup | Output Match |
|-----------|-----------------|------|---------|--------------|
| ~200MB    | 1180ms | 13ms | **91x** | ✓ (md5: 5d642a62) |
| 531MB     | 325ms | 81ms | **4x** | ✓ (md5: 34139a5c) |
| 1.1GB     | 611ms | 184ms | **3.3x** | ✓ (md5: 176f38ab) |

## What Changed

### New: Rust Implementation (`src/main.rs`, `Cargo.toml`)
- Memory-mapped I/O with `memmap2` (zero-copy file access)
- SIMD-optimized pattern matching with `memchr` 
- SQLite extraction with 256MB cap for large files
- Single 2.3MB binary, no runtime dependencies

### Preserved: Python Fallback (`clip-thumbnailer.py`)
- Renamed from `clip-thumbnailer` to `clip-thumbnailer.py`
- Keeps the original implementation intact for systems without Rust
- Automatic fallback during installation if Rust unavailable

### Updated: Installation (`install.sh`)
- Auto-detects Rust and builds binary for CSP thumbnailer
- Falls back to Python if Rust unavailable
- Warns about Dolphin file size limits for large files
- **Note:** Only affects `ClipStudioPaint/install.sh`

## Technical Details

### Why Rust?

The original Python implementation used `tempfile.NamedTemporaryFile` which:
1. Copied entire SQLite database to disk (even 1GB+ files)
2. For large files: 600ms+ just to write the temp file

This implementation:
1. Memory-maps original file (instant, zero-copy)
2. Writes only 256MB of SQLite data to /tmp (enough for CanvasPreview table), this could be shortened more, but I'm playing it safe.
3. Queries preview directly from temp DB

## Testing

**Tested on:** CachyOS with KDE Plasma 6 / Dolphin file manager
**Files tested:** Ranging from 200MB to 1.1GB .clip files
**Verification:** Both Rust and original Python versions produce byte-for-byte identical thumbnails (verified via md5sum)

**Important note for large files:** Dolphin has a default 524MB file size limit for thumbnail generation. For files >500MB, users need to increase this in `~/.config/dolphinrc`:
```ini
[PreviewSettings]
MaximumSize=2147483648  # 2GB limit
```

## Migration Path

For users:
1. Run `./install.sh` - automatically uses Rust if available
2. Python version still works if Rust isn't installed
3. Existing installations will be upgraded seamlessly

For you:
- Python code preserved as `.py` file
- Can still accept Python-only PRs
- Rust version is opt-in during installation

## Files Changed

**Only affects ClipStudioPaint/ directory:**

```
ClipStudioPaint/
├── .gitignore              # Added Rust build artifacts
├── Cargo.toml              # NEW: Rust dependencies
├── src/main.rs             # NEW: Rust implementation  
├── clip-thumbnailer.py     # RENAMED: Python version (was clip-thumbnailer)
└── install.sh              # UPDATED: Rust + Python installer
```


## Why This Matters

Clip Studio Paint files can be **very large** (1GB+) for complex illustrations with many layers. The original Python implementation became slow with these files due to writing the entire SQLite database to a temporary file on disk. This PR makes thumbnails instant regardless of file size, dramatically improving workflow for digital artists working with large projects.

---

**Note:** I'll leave the final decision to you on whether this approach fits your project's direction. If this PR isn't accepted, I'll maintain these optimizations in a fork for my own use. Either way, happy to discuss the implementation or help with future improvements! 

— [eninabox.art](https://eninabox.art)
