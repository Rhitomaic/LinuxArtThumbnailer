#!/usr/bin/env python3
"""
clip-thumbnailer (highly optimized)
Generates thumbnails for Clip Studio Paint (.clip) files.

Usage:
    clip-thumbnailer [input_file] [output_file]

Example:
    clip-thumbnailer artwork.clip /tmp/artwork.png

Credits:
    Thank you so much LavenderSnek for making https://github.com/LavenderSnek/clipdecode
    Optimized with mmap, single-pass search, lazy imports, and minimal I/O
"""

import sys
import mmap

PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"
SQLITE_SIGNATURE = b"SQLite format 3\x00"
IEND_MARKER = b"IEND"
SEARCH_LIMIT = 2 * 1024 * 1024  # Search first 2MB for PNG (most previews < 1MB)

def extract_clip_thumbnail_fast(input_path: str, output_path: str):
    """Extract thumbnail using memory-mapped file for optimal performance."""
    
    with open(input_path, 'rb') as f:
        # Memory-map the file (zero-copy, faster than read())
        with mmap.mmap(f.fileno(), 0, access=mmap.ACCESS_READ) as mm:
            # Find SQLite database offset
            sqlite_offset = mm.find(SQLITE_SIGNATURE)
            if sqlite_offset == -1:
                raise RuntimeError("No SQLite header found in clip file")
            
            # Try direct PNG extraction (single pass, no SQLite overhead)
            search_end = min(sqlite_offset + SEARCH_LIMIT, len(mm))
            png_start = mm.find(PNG_SIGNATURE, sqlite_offset, search_end)
            
            if png_start != -1:
                # Find PNG end marker
                iend_pos = mm.find(IEND_MARKER, png_start, search_end)
                if iend_pos != -1:
                    # Extract complete PNG (IEND + 4 byte CRC)
                    with open(output_path, 'wb') as out:
                        out.write(mm[png_start:iend_pos + 8])
                    return True
            
            # Fallback: Use SQLite if direct extraction fails
            # Extract only the SQLite portion
            sqlite_data = mm[sqlite_offset:]
    
    # Lazy import sqlite3 (only if direct extraction failed)
    import sqlite3
    
    # SQLite fallback (only runs if direct extraction failed)
    conn = sqlite3.connect(":memory:")
    conn.deserialize(bytes(sqlite_data))
    
    try:
        cur = conn.cursor()
        cur.execute("SELECT ImageData FROM CanvasPreview LIMIT 1;")
        row = cur.fetchone()
        
        if not row or row[0] is None:
            raise RuntimeError("No CanvasPreview image found in this .clip file")
        
        # Extract PNG from blob
        blob = row[0]
        p = blob.find(PNG_SIGNATURE)
        
        if p != -1:
            end = blob.find(IEND_MARKER, p)
            if end != -1:
                with open(output_path, 'wb') as out:
                    out.write(blob[p:end+8])
                return True
        
        # Final fallback: write entire blob
        with open(output_path, 'wb') as out:
            out.write(blob)
        return True
    finally:
        conn.close()

if __name__ == "__main__":
    if len(sys.argv) < 3:
        sys.stderr.write("Usage: clip-thumbnailer [input_file] [output_file]\n")
        sys.exit(1)
    
    try:
        extract_clip_thumbnail_fast(sys.argv[1], sys.argv[2])
    except Exception as e:
        sys.stderr.write(f"Error: {e}\n")
        sys.exit(1)
