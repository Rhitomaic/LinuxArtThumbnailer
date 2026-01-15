use memmap2::Mmap;
use memchr::memmem;
use std::env;
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;
use std::process;

const PNG_SIGNATURE: &[u8] = b"\x89PNG\r\n\x1a\n";
const SQLITE_SIGNATURE: &[u8] = b"SQLite format 3\0";
const IEND_MARKER: &[u8] = b"IEND";

fn extract_thumbnail(input_path: &str, output_path: &str) -> Result<(), String> {
    use rusqlite::Connection;
    
    // Memory-map the input file
    let file = File::open(input_path)
        .map_err(|e| format!("Failed to open input file: {}", e))?;
    
    let mmap = unsafe { Mmap::map(&file) }
        .map_err(|e| format!("Failed to mmap file: {}", e))?;
    
    // Find SQLite database offset
    let sqlite_offset = memmem::find(&mmap, SQLITE_SIGNATURE)
        .ok_or("No SQLite header found in clip file")?;
    
    // Create temporary DB for SQLite query
    let tmp_db = format!("/tmp/clip-thumbnailer-{}.db", std::process::id());
    
    // Write SQLite data to temp file with a reasonable size limit
    // Most CanvasPreview data is in the first part of the DB
    // Limit to 256MB to avoid timeout on massive files (1GB+)
    let sqlite_data = &mmap[sqlite_offset..];
    let write_size = sqlite_data.len().min(256 * 1024 * 1024); // 256MB max
    
    {
        let mut tmp_file = File::create(&tmp_db)
            .map_err(|e| format!("Failed to create temp DB: {}", e))?;
        tmp_file.write_all(&sqlite_data[..write_size])
            .map_err(|e| format!("Failed to write temp DB: {}", e))?;
    }
    
    let conn = Connection::open(&tmp_db)
        .map_err(|e| format!("Failed to open SQLite: {}", e))?;
    
    let blob: Vec<u8> = conn
        .query_row("SELECT ImageData FROM CanvasPreview LIMIT 1", [], |row| row.get(0))
        .map_err(|e| format!("Failed to query CanvasPreview: {}", e))?;
    
    // Extract PNG from blob (full search - no limit)
    let png_pos = memmem::find(&blob, PNG_SIGNATURE)
        .ok_or("PNG signature not found in blob")?;
    let iend_pos = memmem::find(&blob[png_pos..], IEND_MARKER)
        .ok_or("IEND not found in blob")?;
    let png_end = png_pos + iend_pos + 8;
    
    if png_end > blob.len() {
        return Err("PNG extends beyond blob".to_string());
    }
    
    if let Some(parent) = Path::new(output_path).parent() {
        fs::create_dir_all(parent)
            .map_err(|e| format!("Failed to create output directory: {}", e))?;
    }
    
    let mut output = File::create(output_path)
        .map_err(|e| format!("Failed to create output file: {}", e))?;
    
    output.write_all(&blob[png_pos..png_end])
        .map_err(|e| format!("Failed to write PNG data: {}", e))?;
    
    drop(conn);
    let _ = fs::remove_file(&tmp_db);
    
    Ok(())
}

fn main() {
    let args: Vec<String> = env::args().collect();
    
    if args.len() < 3 {
        eprintln!("Usage: clip-thumbnailer [input_file] [output_file]");
        process::exit(1);
    }
    
    if let Err(e) = extract_thumbnail(&args[1], &args[2]) {
        eprintln!("Error: {}", e);
        process::exit(1);
    }
}

