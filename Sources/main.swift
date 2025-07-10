
import Foundation
import AVFoundation
import ImageIO
import AppKit

struct FileInfo {
    let name: String
    let path: String
    let size: UInt64
}

func fileSize(path: String) -> UInt64 {
    let attr = try? FileManager.default.attributesOfItem(atPath: path)
    return attr?[FileAttributeKey.size] as? UInt64 ?? 0
}

func generateVideoThumbnail(from path: String, to outputFolder: URL) throws -> String {
    let asset = AVAsset(url: URL(fileURLWithPath: path))
    let imageGenerator = AVAssetImageGenerator(asset: asset)
    imageGenerator.appliesPreferredTrackTransform = true
    let time = CMTime(seconds: 1.0, preferredTimescale: 600)
    let cgImage = try imageGenerator.copyCGImage(at: time, actualTime: nil)
    let image = NSImage(cgImage: cgImage, size: .zero)
    return try saveImage(image, for: path, to: outputFolder)
}

func generateImageThumbnail(from path: String, to outputFolder: URL) throws -> String {
    let url = URL(fileURLWithPath: path)
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else {
        throw NSError(domain: "ImageSourceError", code: 0, userInfo: nil)
    }

    let options: [NSString: Any] = [
        kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
        kCGImageSourceThumbnailMaxPixelSize: 512,
        kCGImageSourceCreateThumbnailWithTransform: true
    ]

    guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(src, 0, options as CFDictionary) else {
        throw NSError(domain: "ThumbnailError", code: 0, userInfo: nil)
    }

    let image = NSImage(cgImage: thumbnail, size: .zero)
    return try saveImage(image, for: path, to: outputFolder)
}

func saveImage(_ image: NSImage, for path: String, to outputFolder: URL) throws -> String {
    guard let data = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: data),
          let jpegData = rep.representation(using: .jpeg, properties: [:]) else {
        throw NSError(domain: "ImageSaveError", code: 0, userInfo: nil)
    }

    let fileName = "\(URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent)_\(timestamp()).jpg"
    let outputPath = outputFolder.appendingPathComponent(fileName)
    try jpegData.write(to: outputPath)
    return fileName
}

func timestamp() -> String {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd-HHmmss"
    return formatter.string(from: Date())
}

func isVideoFile(_ file: String) -> Bool {
    let ext = (file as NSString).pathExtension.lowercased()
    return ["mp4", "mov", "m4v"].contains(ext)
}

func isImageFile(_ file: String) -> Bool {
    let ext = (file as NSString).pathExtension.lowercased()
    return ["jpg", "jpeg", "png", "tif", "tiff", "psd",
            "cr2", "cr3", "nef", "arw", "dng", "rw2"].contains(ext)
}

let args = CommandLine.arguments.dropFirst()
guard !args.isEmpty else {
    print("Usage: gen-thumb [file1] [file2] ...")
    exit(1)
}

let outputFolder = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

var total = 0
for path in args {
    let start = CFAbsoluteTimeGetCurrent()
    let size = fileSize(path: path)
    do {
        let fileName: String
        if isVideoFile(path) {
            fileName = try generateVideoThumbnail(from: path, to: outputFolder)
        } else if isImageFile(path) {
            fileName = try generateImageThumbnail(from: path, to: outputFolder)
        } else {
            print("⚠️ Skipped unsupported file: \(path)")
            continue
        }
        let duration = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print("✅ \(fileName) | Size: \(size / 1024) KB | Time: \(String(format: "%.2f", duration)) ms")
        total += 1
    } catch {
        print("❌ Error processing \(path): \(error.localizedDescription)")
    }
}

print("🎉 Done. Total thumbnails generated: \(total)")
