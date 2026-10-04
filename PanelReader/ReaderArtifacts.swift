import Foundation
import PDFKit
import UIKit
import ImageIO

struct PageTextNote: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let bookID: UUID
    let page: Int
    var text: String
    var updatedAt: Date

    init(id: UUID = UUID(), bookID: UUID, page: Int, text: String, updatedAt: Date = .now) {
        self.id = id
        self.bookID = bookID
        self.page = page
        self.text = text
        self.updatedAt = updatedAt
    }
}

struct SavedPanel: Identifiable, Codable, Hashable, Sendable {
    let id: UUID
    let bookID: UUID
    let page: Int
    let imageFileName: String
    let createdAt: Date

    init(id: UUID = UUID(), bookID: UUID, page: Int, imageFileName: String, createdAt: Date = .now) {
        self.id = id
        self.bookID = bookID
        self.page = page
        self.imageFileName = imageFileName
        self.createdAt = createdAt
    }
}

struct AnnotationPageSummary: Identifiable, Hashable {
    let bookID: UUID
    let page: Int
    let hasPencilDrawing: Bool
    let textNote: String?

    var id: String { "\(bookID.uuidString)-\(page)" }
}

private final class PageSnapshotDataBox: @unchecked Sendable {
    let data: Data?
    init(_ data: Data?) { self.data = data }
}

enum ReaderPageSnapshotService {
    static func loadSnapshot(
        fileURL: URL,
        type: ComicType,
        page: Int,
        settings: ReaderSettings,
        maxPixel: Int = 2400
    ) async -> Data? {
        let box = await Task.detached(priority: .userInitiated) {
            switch type {
            case .pdf:
                return PageSnapshotDataBox(pdfSnapshot(
                    fileURL: fileURL,
                    pageIndex: page,
                    settings: settings,
                    maxPixel: maxPixel
                ))
            case .cbz:
                return PageSnapshotDataBox(cbzSnapshot(
                    fileURL: fileURL,
                    pageIndex: page,
                    maxPixel: maxPixel
                ))
            }
        }.value
        return box.data
    }

    private static func pdfSnapshot(
        fileURL: URL,
        pageIndex: Int,
        settings: ReaderSettings,
        maxPixel: Int
    ) -> Data? {
        guard let document = PDFDocument(url: fileURL),
              pageIndex >= 0,
              pageIndex < document.pageCount,
              let page = document.page(at: pageIndex) else { return nil }

        let media = page.bounds(for: .mediaBox)
        var normalized = NormalizedCropRect.full
        if settings.autoCropEnabled {
            normalized = PDFAutoCropService.detectNormalizedCrop(
                fileURL: fileURL,
                pageIndex: pageIndex,
                strength: settings.cropStrength,
                trimFooter: settings.trimWebFooter,
                fullBleed: settings.fullBleed
            )
        }
        normalized = normalized.applyingManual(settings.manualCrop)
        let crop = PDFAutoCropService.pdfRect(from: normalized, mediaBox: media)
        if crop.width > 1, crop.height > 1 {
            page.setBounds(crop, for: .cropBox)
        }

        let bounds = page.bounds(for: .cropBox)
        guard bounds.width > 0, bounds.height > 0 else { return nil }
        let scale = min(
            CGFloat(maxPixel) / max(bounds.width, bounds.height),
            3.0
        )
        let size = CGSize(
            width: max(1, bounds.width * scale),
            height: max(1, bounds.height * scale)
        )
        return page.thumbnail(of: size, for: .cropBox).jpegData(compressionQuality: 0.92)
    }

    private static func cbzSnapshot(
        fileURL: URL,
        pageIndex: Int,
        maxPixel: Int
    ) -> Data? {
        guard let pages = try? CBZService.extractImages(from: fileURL),
              pageIndex >= 0,
              pageIndex < pages.count else { return nil }

        let pageURL = pages[pageIndex]
        let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let source = CGImageSourceCreateWithURL(pageURL as CFURL, sourceOptions) else { return nil }

        let options = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixel,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary

        guard let cg = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else { return nil }
        return UIImage(cgImage: cg).jpegData(compressionQuality: 0.92)
    }

    static func cropJPEG(
        sourceData: Data,
        top: Double,
        leading: Double,
        bottom: Double,
        trailing: Double
    ) -> Data? {
        guard let image = UIImage(data: sourceData),
              let cg = image.cgImage else { return nil }

        let l = max(0, min(0.45, leading))
        let r = max(0, min(0.45, trailing))
        let t = max(0, min(0.45, top))
        let b = max(0, min(0.45, bottom))

        let usableW = max(0.10, 1 - l - r)
        let usableH = max(0.10, 1 - t - b)
        let rect = CGRect(
            x: CGFloat(l) * CGFloat(cg.width),
            y: CGFloat(t) * CGFloat(cg.height),
            width: CGFloat(usableW) * CGFloat(cg.width),
            height: CGFloat(usableH) * CGFloat(cg.height)
        ).integral.intersection(CGRect(x: 0, y: 0, width: cg.width, height: cg.height))

        guard rect.width >= 10, rect.height >= 10,
              let cropped = cg.cropping(to: rect) else { return nil }

        return UIImage(cgImage: cropped).jpegData(compressionQuality: 0.90)
    }
}
