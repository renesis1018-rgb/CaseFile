import Foundation
import CoreData
import AppKit
import ImageIO

class PhotoManager {
    static let shared = PhotoManager()
    
    // EXIF日付を抽出
    func extractEXIFDate(from imageData: Data) -> Date? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let exifDict = properties[kCGImagePropertyExifDictionary as String] as? [String: Any],
              let dateString = exifDict[kCGImagePropertyExifDateTimeOriginal as String] as? String else {
            return nil
        }
        
        // EXIF日付フォーマット: "yyyy:MM:dd HH:mm:ss"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone.current
        return formatter.date(from: dateString)
    }
    
    // 手術日との経過日数を計算
    func calculateDaysAfterSurgery(surgeryDate: Date, photoDate: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: surgeryDate, to: photoDate)
        return components.day ?? 0
    }
    
    // 時期を推定 (Day XX形式対応)
    func estimateTiming(from daysAfterSurgery: Int) -> String {
        switch daysAfterSurgery {
        case ..<0:
            return "術前"
        case 0...10:
            return "1W"
        case 25...35:
            return "1M"
        case 80...100:
            return "3M"
        case 170...190:
            return "6M"
        case 350...380:
            return "12M"
        default:
            return "Day \(daysAfterSurgery)"
        }
    }
    
    // サムネイル生成
    func generateThumbnail(from imageData: Data, maxSize: CGFloat = 200) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil) else { return nil }
        
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageIfAbsent: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxSize
        ]
        
        guard let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) else {
            return nil
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: thumbnail)
        return bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.7])
    }
    
    // 写真を保存（部位情報対応版）
    func savePhoto(
        context: NSManagedObjectContext,
        surgery: Surgery,
        imageData: Data,
        angle: String,
        notes: String?,
        surgeryDate: Date,
        bodyPart: String?  // ← 新規追加: 部位情報（"胸" or "ドナー部位"）
    ) {
        let photo = Photo(context: context)
        photo.id = UUID()
        photo.imageData = imageData
        photo.angle = angle
        photo.notes = notes
        photo.uploadDate = Date()
        photo.surgery = surgery
        photo.bodypart = bodyPart  // ← 新規追加: 部位情報を保存
        
        // EXIF日付を抽出
        if let exifDate = extractEXIFDate(from: imageData) {
            photo.exifDate = exifDate
            
            // 手術日との経過日数を計算
            let daysAfter = calculateDaysAfterSurgery(surgeryDate: surgeryDate, photoDate: exifDate)
            photo.daysAfterSurgery = NSNumber(value: daysAfter)
            
            // 時期を推定 (Day XX形式対応)
            photo.timing = estimateTiming(from: daysAfter)
            
            print("📅 写真保存: EXIF日付=\(exifDate), 手術日=\(surgeryDate), 経過日数=\(daysAfter), 時期=\(photo.timing ?? "nil"), 部位=\(bodyPart ?? "未設定")")
        } else {
            // EXIF日付がない場合は術前として扱う
            photo.timing = "術前"
            print("⚠️ EXIF日付なし → 術前として保存 / 部位=\(bodyPart ?? "未設定")")
        }
        
        // サムネイル生成
        if let thumbnailData = generateThumbnail(from: imageData) {
            photo.thumbnail = thumbnailData
        }
        
        do {
            try context.save()
            print("✅ 写真保存成功: \(photo.timing ?? "nil") / \(angle) / \(bodyPart ?? "未設定")")
        } catch {
            print("❌ 写真保存失敗: \(error)")
        }
    }
    
    // 写真を削除
    func deletePhoto(context: NSManagedObjectContext, photo: Photo) {
        context.delete(photo)
        do {
            try context.save()
            print("✅ 写真削除成功")
        } catch {
            print("❌ 写真削除失敗: \(error)")
        }
    }
}
