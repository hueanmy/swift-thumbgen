# swift-thumbgen

A lightweight Swift-based CLI tool to generate thumbnails from both **videos** and **images** on macOS.  
Supports most common image formats (JPEG, PNG, RAW...) and video formats (MP4, MOV...).

> Built with `AVFoundation`, `CoreGraphics`, and `AppKit`.  
> Output includes rich metadata such as dimensions, rotation, datetime, rating, and codec info.

---

## ✨ Features

- 🖼️ Generate thumbnails for:
  - **Videos**: `.mp4`, `.mov`, `.m4v`
  - **Images**: `.jpg`, `.jpeg`, `.png`, `.tif`, `.tiff`, `.psd`, `.cr2`, `.cr3`, `.nef`, `.arw`, `.dng`, `.rw2`

- 🧠 Extracts metadata (if available):
  - Videos: `duration`, `frame_rate`, `width`, `height`, `rotation`, `codec`
  - Images: `created_datetime`, `rotation`, `rating`, `label`

- 📸 Output: `.jpg` thumbnails named with timestamps and unique suffixes (avoid overwrite)

- ⚡ Fast and simple CLI – no GUI needed

- 🧩 Supports batch processing of multiple files

---

## 🚀 Usage

```bash
swift-thumbgen [options] [file1] [file2] ...
```

### Example:

```bash
swift-thumbgen --thumbsize=400 video.mov image.cr2 image2.jpg
```

This will generate thumbnails with max dimensions 400×400 px and save them in the **current directory**:

```
video_20250730-161002_3F9A21B8.jpg
image_20250730-161003_EF123AC9.jpg
```

---

## ⚙️ Options

| Option             | Description                              | Default |
|--------------------|------------------------------------------|---------|
| `--thumbsize=XXX`  | Max width/height of thumbnail in pixels  | `200`   |

---

## 🛠 Build & Run

### ✅ Build (Debug – for development)

```bash
swift build
```

### ✅ Build (Release – optimized)

```bash
swift build -c release
```

> The binary will be created at:
>
> ```
> .build/release/swift-thumbgen
> ```

---

### ▶️ Run the tool

#### From Swift:

```bash
swift run swift-thumbgen file1 file2 ...
```

#### From compiled binary:

```bash
.build/release/swift-thumbgen file1 file2 ...
```

---

### 📦 (Optional) Install globally:

```bash
install .build/release/swift-thumbgen /usr/local/bin/swift-thumbgen
```

Then use anywhere:

```bash
swift-thumbgen myvideo.mov myphoto.arw
```

---

## 📂 Output Files

- Output thumbnails are saved in the current working directory
- Output file format:  
  ```
  [original-filename]_[timestamp]_[random].jpg
  ```

  Example:

  ```
  image_20250730-153413_F3A9C4D1.jpg
  ```

---

## 🧪 Known Limitations

- Only supports macOS
- RAW image thumbnail support depends on system codec support (e.g., `.cr2`, `.nef`, `.arw`)
- Metadata extraction varies by file format

---


---

## 🏗️ Build with Script

You can use the provided shell script to build native binaries for:

- Apple Silicon (arm64)
- Intel (x86_64)
- Universal (runs on both)

### ▶️ Usage

```bash
chmod +x ./build.sh
./build.sh
```

This will output:

- `.build/release/swift-thumbgen-arm64`
- `.build/release/swift-thumbgen-x86_64`
- `.build/release/swift-thumbgen` (universal)

You can then install globally with:

```bash
install .build/release/swift-thumbgen /usr/local/bin/swift-thumbgen
```

---
## 📋 License

MIT © 2025 Meii