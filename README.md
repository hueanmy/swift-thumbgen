# swift-thumbgen

A lightweight Swift-based CLI tool to generate thumbnails from both **videos** and **images** on macOS.  
Supports most common image formats (JPEG, PNG, RAW...) and video formats (MP4, MOV...).

> Built with `AVFoundation`, `CoreGraphics`, and `AppKit`.

---

## ✨ Features

- 🖼️ Generate thumbnails for:
  - Videos: `.mp4`, `.mov`, `.m4v`
  - Images: `.jpg`, `.jpeg`, `.png`, `.tif`, `.tiff`, `.psd`, `.cr2`, `.cr3`, `.nef`, `.arw`, `.dng`, `.rw2`
- 💾 Output: `.jpg` thumbnails named with timestamps
- ⚡ Fast and simple CLI – no GUI needed

---

## 🚀 Usage

```bash
swift-thumbgen [file1] [file2] ...
```

Example:

```bash
swift-thumbgen /Users/you/video.mov /Users/you/image.cr2
```

Outputs thumbnails into the **current directory** with names like:

```
video_20250710-153412.jpg
image_20250710-153413.jpg
```

---

## 🛠 How to Build & Run

### ✅ Build (Debug mode – for development)

```bash
swift build
```

### ✅ Build (Release mode – optimized for performance)

```bash
swift build -c release
```

> The executable will be created at:
>
> ```
> .build/release/swift-thumbgen
> ```

---

### ▶️ Run the CLI tool

#### From Swift (debug/release):

```bash
swift run swift-thumbgen /path/to/video.mp4 /path/to/image.jpg
```

#### Or run the release binary directly:

```bash
.build/release/swift-thumbgen file1 file2 ...
```

---

### 📦 (Optional) Install globally on your machine:

```bash
install .build/release/swift-thumbgen /usr/local/bin/swift-thumbgen
```

Then run anywhere:

```bash
swift-thumbgen myvideo.mov
```

---

## 📋 License

MIT © 2025 Meii
