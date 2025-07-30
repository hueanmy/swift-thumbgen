import Foundation
import AVFoundation
import ImageIO
import ImageIO.CGImageProperties
import AppKit

// ✅ Define manually to fix XMP metadata constant error
let kCGImagePropertyXMPDictionary = "kCGImagePropertyXMPDictionary" as CFString

// MARK: - Helpers

func fileSize(path: String) -> UInt64 {
    let attr = try? FileManager.default.attributesOfItem(atPath: path)
    return attr?[.size] as? UInt64 ?? 0
}

func timestamp() -> String {
    let f = DateFormatter()
    f.dateFormat = "yyyyMMdd-HHmmss"
    return f.string(from: Date())
}

func isVideo(_ file: String) -> Bool {
    let ext = (file as NSString).pathExtension.lowercased()
    return ["mp4", "mov", "m4v"].contains(ext)
}

func isImage(_ file: String) -> Bool {
    let ext = (file as NSString).pathExtension.lowercased()
    return ["jpg", "jpeg", "png", "tif", "tiff", "psd", "cr2", "cr3", "nef", "arw", "dng", "rw2"].contains(ext)
}

// MARK: - Thumbnail

func saveImage(_ image: NSImage, for path: String, to folder: URL) throws -> String {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let jpeg = rep.representation(using: .jpeg, properties: [:]) else {
        throw NSError(domain: "ImageSaveError", code: 0, userInfo: nil)
    }

    let baseName = URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    let name = "\(baseName)_\(timestamp()).jpg"
    let outputPath = folder.appendingPathComponent(name)
    try jpeg.write(to: outputPath)
    return name
}

func generateVideoThumbnail(from path: String, to outputFolder: URL, thumbSize: CGFloat) throws -> String {
    let asset = AVAsset(url: URL(fileURLWithPath: path))
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    generator.maximumSize = CGSize(width: thumbSize, height: thumbSize)
    let time = CMTime(seconds: 1.0, preferredTimescale: 600)
    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
    let image = NSImage(cgImage: cgImage, size: .zero)
    return try saveImage(image, for: path, to: outputFolder)
}

func generateImageThumbnail(from path: String, to outputFolder: URL, thumbSize: Int) throws -> String {
    let url = URL(fileURLWithPath: path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        throw NSError(domain: "ImageSourceError", code: 0, userInfo: nil)
    }

    let options: [NSString: Any] = [
        kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
        kCGImageSourceThumbnailMaxPixelSize: thumbSize,
        kCGImageSourceCreateThumbnailWithTransform: true
    ]

    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else {
        throw NSError(domain: "ThumbnailError", code: 0, userInfo: nil)
    }

    let image = NSImage(cgImage: thumbnail, size: .zero)
    return try saveImage(image, for: path, to: outputFolder)
}

// MARK: - Metadata

func getVideoMetadata(from path: String) -> [String: Any] {
    var metadata: [String: Any] = [:]
    let asset = AVAsset(url: URL(fileURLWithPath: path))

    metadata["duration"] = CMTimeGetSeconds(asset.duration)
    metadata["hasProtectedContent"] = asset.hasProtectedContent
    metadata["isPlayable"] = asset.isPlayable
    metadata["isReadable"] = asset.isReadable
    metadata["trackCount"] = asset.tracks.count
    metadata["creationDate"] = asset.creationDate?.value ?? "n/a"

    if let videoTrack = asset.tracks(withMediaType: .video).first {
        metadata["width"] = Int(videoTrack.naturalSize.width)
        metadata["height"] = Int(videoTrack.naturalSize.height)
        metadata["frame_rate"] = videoTrack.nominalFrameRate
        metadata["rotation"] = String(describing: videoTrack.preferredTransform)

        if let desc = (videoTrack.formatDescriptions as? [CMFormatDescription])?.first {
            let codecType = CMFormatDescriptionGetMediaSubType(desc)
            let codecString = String(format: "%c%c%c%c",
                                     (codecType >> 24) & 0xff,
                                     (codecType >> 16) & 0xff,
                                     (codecType >> 8) & 0xff,
                                     codecType & 0xff)
            metadata["codec"] = codecString
        }
    }

    if let audioTrack = asset.tracks(withMediaType: .audio).first {
        metadata["audio_sample_rate"] = audioTrack.naturalTimeScale
        metadata["audio_channels"] = audioTrack.formatDescriptions.count
    }

    for item in asset.metadata {
        if let key = item.commonKey?.rawValue, let value = item.value {
            metadata["meta_\(key)"] = value
        }
    }

    return metadata
}

func getImageMetadata(from path: String) -> [String: Any] {
    let url = URL(fileURLWithPath: path)
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        return [:]
    }

    var metadata: [String: Any] = [:]
    let all = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] ?? [:]
    var created: Any = "n/a"

    if let exif = all[kCGImagePropertyExifDictionary] as? [CFString: Any],
       let date = exif[kCGImagePropertyExifDateTimeOriginal] {
        metadata["created_datetime"] = date
        created = date
    }

    if created as? String == "n/a",
       let tiff = all[kCGImagePropertyTIFFDictionary] as? [CFString: Any],
       let date = tiff[kCGImagePropertyTIFFDateTime] {
        metadata["created_datetime"] = date
        created = date
    }

    if created as? String == "n/a",
       let attrs = try? FileManager.default.attributesOfItem(atPath: path),
       let date = attrs[.creationDate] as? Date {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy:MM:dd HH:mm:ss"
        metadata["created_datetime"] = fmt.string(from: date)
    }

    if let xmp = all[kCGImagePropertyXMPDictionary] as? [CFString: Any] {
        metadata["rating"] = xmp["Rating" as CFString] ?? "n/a"
        metadata["label"] = xmp["Label" as CFString] ?? "n/a"
    }

    if let orientation = all[kCGImagePropertyOrientation] {
        metadata["rotation"] = orientation
    }

    return metadata
}

// MARK: - CLI Entry

var args = CommandLine.arguments.dropFirst()
var thumbSize = 200

if let i = args.firstIndex(where: { $0.starts(with: "--thumbsize=") }) {
    let value = args[i].replacingOccurrences(of: "--thumbsize=", with: "")
    if let parsed = Int(value), parsed > 0 {
        thumbSize = parsed
    }
    args.remove(at: i)
}

guard !args.isEmpty else {
    print("Usage: gen-thumb.swift [--thumbsize=200] file1 file2 ...")
    exit(1)
}

let outputDir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
var total = 0

for path in args {
    let size = fileSize(path: path)
    let start = CFAbsoluteTimeGetCurrent()
    do {
        let fileName: String
        if isVideo(path) {
            fileName = try generateVideoThumbnail(from: path, to: outputDir, thumbSize: CGFloat(thumbSize))
            let meta = getVideoMetadata(from: path)
            if !meta.isEmpty {
                print("📊 Video Metadata for \(fileName):")
                for (k, v) in meta {
                    print("   \(k): \(v)")
                }
            }
        } else if isImage(path) {
            fileName = try generateImageThumbnail(from: path, to: outputDir, thumbSize: thumbSize)
            let meta = getImageMetadata(from: path)
            if !meta.isEmpty {
                print("📊 Image Metadata for \(fileName):")
                for (k, v) in meta {
                    print("   \(k): \(v)")
                }
            }
        } else {
            print("⚠️ Skipped unsupported file: \(path)")
            continue
        }
        let time = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print("✅ \(fileName) | Size: \(size / 1024) KB | Time: \(String(format: "%.2f", time)) ms\n")
        total += 1
    } catch {
        print("❌ Error processing \(path): \(error.localizedDescription)")
    }
}

print("🎉 Done. Total thumbnails generated: \(total)")