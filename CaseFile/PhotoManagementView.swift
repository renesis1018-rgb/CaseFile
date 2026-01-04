//
//  PhotoManagementView.swift
//  CaseFile
//
//  写真管理ビュー - 部位別フィルター対応版
//

import SwiftUI
import CoreData

struct PhotoManagementView: View {
    let surgery: Surgery
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest private var photos: FetchedResults<Photo>
    
    @State private var showUploadView = false
    @State private var showPhotoViewer = false
    @State private var selectedPhotoIndex = 0
    @State private var showDeleteAlert = false
    @State private var photoToDelete: Photo? = nil
    @State private var displayMode: DisplayMode = .byTiming
    @State private var showComparisonView = false
    @State private var bodyPartFilter: BodyPartFilter = .all  // ✅ 追加: 部位フィルター
    
    // ✅ 追加: 部位フィルター
    enum BodyPartFilter: String, CaseIterable, Identifiable {
        case all = "すべて"
        case chest = "胸"
        case donor = "ドナー部位"
        case unspecified = "未分類"
        
        var id: String { rawValue }
    }
    
    enum DisplayMode {
        case byTiming  // 時期別表示
        case byAngle   // 角度別表示
    }
    
    // ✅ 追加: 脂肪注入かどうかを判定
    private var isFatGraft: Bool {
        // procedureフィールドをチェック
        if let procedure = surgery.procedure?.lowercased(),
           procedure.contains("脂肪注入") || procedure.contains("fat") || procedure.contains("graft") {
            return true
        }
        
        // surgeryTypeフィールドもチェック
        if let surgeryType = surgery.surgeryType?.lowercased(),
           surgeryType.contains("脂肪注入") || surgeryType.contains("fat") {
            return true
        }
        
        return false
    }
    
    // ✅ 追加: 部位でフィルタリングされた写真
    private var filteredPhotos: [Photo] {
        let allPhotos = Array(photos)
        
        switch bodyPartFilter {
        case .all:
            return allPhotos
        case .chest:
            return allPhotos.filter { $0.bodypart == "胸" }
        case .donor:
            return allPhotos.filter { $0.bodypart == "ドナー部位" }
        case .unspecified:
            return allPhotos.filter { $0.bodypart == nil || $0.bodypart?.isEmpty == true }
        }
    }
    
    init(surgery: Surgery) {
        self.surgery = surgery
        
        // この手術に紐づく写真のみを取得
        _photos = FetchRequest<Photo>(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Photo.exifDate, ascending: true)
            ],
            predicate: NSPredicate(format: "surgery == %@", surgery)
        )
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("📸 写真管理")
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // ✅ 追加: 部位フィルター（脂肪注入のみ表示）
                if isFatGraft {
                    Picker("部位", selection: $bodyPartFilter) {
                        ForEach(BodyPartFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 300)
                }
                
                // Before/After 比較ボタン
                Button {
                    showComparisonView = true
                } label: {
                    Label("Before/After", systemImage: "arrow.left.and.right")
                }
                .buttonStyle(.bordered)
                .disabled(filteredPhotos.isEmpty)
                
                // 表示モード切り替え
                Picker("表示モード", selection: $displayMode) {
                    Text("時期別").tag(DisplayMode.byTiming)
                    Text("角度別").tag(DisplayMode.byAngle)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
                
                Button {
                    showUploadView = true
                } label: {
                    Label("写真を追加", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            if filteredPhotos.isEmpty {
                // 写真がない場合
                VStack(spacing: 20) {
                    Image(systemName: "photo.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text(bodyPartFilter == .all ? "写真がまだありません" : "\(bodyPartFilter.rawValue)の写真がありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Button("写真を追加") {
                        showUploadView = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // 写真一覧
                ScrollView {
                    if displayMode == .byTiming {
                        photosByTimingView
                    } else {
                        photosByAngleView
                    }
                }
            }
        }
        .sheet(isPresented: $showUploadView) {
            PhotoUploadView(surgery: surgery)
        }
        .sheet(isPresented: $showPhotoViewer) {
            PhotoViewerView(photos: filteredPhotos, initialIndex: selectedPhotoIndex)
        }
        .sheet(isPresented: $showComparisonView) {
            BeforeAfterComparisonView(
                photos: filteredPhotos,
                isFatGraft: isFatGraft,
                initialBodyPartFilter: bodyPartFilter
            )
        }
        .alert("写真を削除", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                if let photo = photoToDelete {
                    deletePhoto(photo)
                }
            }
        } message: {
            Text("この写真を削除してもよろしいですか?")
        }
    }
    
    // MARK: - 時期別表示
    
    private var photosByTimingView: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(groupedByTiming.sorted(by: { timingOrder($0.key) < timingOrder($1.key) }), id: \.key) { timing, photos in
                VStack(alignment: .leading, spacing: 10) {
                    // 時期ヘッダー
                    HStack {
                        Text("📅 \(timing)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("(\(photos.count)枚)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // 角度別にグループ化して表示
                    ForEach(groupPhotosByAngle(photos).sorted(by: { angleOrder($0.key) < angleOrder($1.key) }), id: \.key) { angle, anglePhotos in
                        VStack(alignment: .leading, spacing: 5) {
                            Text("   \(angle)")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .padding(.leading)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(anglePhotos) { photo in
                                        PhotoThumbnailWithBodyPart(
                                            photo: photo,
                                            showBodyPart: isFatGraft && bodyPartFilter == .all
                                        )
                                        .onTapGesture {
                                            openPhotoViewer(photo: photo)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - 角度別表示
    
    private var photosByAngleView: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(groupedByAngle.sorted(by: { angleOrder($0.key) < angleOrder($1.key) }), id: \.key) { angle, photos in
                VStack(alignment: .leading, spacing: 10) {
                    // 角度ヘッダー
                    HStack {
                        Text("📐 \(angle)")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("(\(photos.count)枚)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    // 時期順に表示
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(photos.sorted(by: { timingOrder($0.timing ?? "") < timingOrder($1.timing ?? "") })) { photo in
                                VStack {
                                    PhotoThumbnailWithBodyPart(
                                        photo: photo,
                                        showBodyPart: isFatGraft && bodyPartFilter == .all
                                    )
                                    Text(photo.timing ?? "")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .onTapGesture {
                                    openPhotoViewer(photo: photo)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .padding(.vertical)
    }
    
    // MARK: - Helper Functions
    
    private var groupedByTiming: [String: [Photo]] {
        Dictionary(grouping: filteredPhotos) { photo in
            photo.timing ?? "その他"
        }
    }
    
    private var groupedByAngle: [String: [Photo]] {
        Dictionary(grouping: filteredPhotos) { photo in
            photo.angle ?? "その他"
        }
    }
    
    private func groupPhotosByAngle(_ photos: [Photo]) -> [String: [Photo]] {
        Dictionary(grouping: photos) { photo in
            photo.angle ?? "その他"
        }
    }
    
    private func timingOrder(_ timing: String) -> Int {
        switch timing {
        case "術前": return 0
        case "1W": return 1
        case "1M": return 2
        case "3M": return 3
        case "6M": return 4
        case "12M": return 5
        default:
            // Day XX 形式の場合は日数を抽出
            if timing.starts(with: "Day ") {
                let dayString = timing.replacingOccurrences(of: "Day ", with: "")
                if let days = Int(dayString) {
                    return 100 + days  // 100以降で日数順
                }
            }
            return 999
        }
    }
    
    private func angleOrder(_ angle: String) -> Int {
        // 術式に応じた角度順序
        if let surgeryTypeString = surgery.surgeryType,
           let surgeryType = SurgeryType(rawValue: surgeryTypeString) {
            let angles = surgeryType.photoAngles
            if let index = angles.firstIndex(of: angle) {
                return index
            }
        }
        
        // デフォルトの順序（5方向 + 8方向対応）
        switch angle {
        case "正面": return 0
        case "右側面": return 1
        case "右斜め": return 2
        case "左斜め": return 3
        case "左側面": return 4
        case "左斜め後ろ": return 5
        case "背面": return 6
        case "右斜め後ろ": return 7
        default: return 99
        }
    }
    
    private func openPhotoViewer(photo: Photo) {
        if let index = filteredPhotos.firstIndex(of: photo) {
            selectedPhotoIndex = index
            showPhotoViewer = true
        }
    }
    
    private func deletePhoto(_ photo: Photo) {
        PhotoManager.shared.deletePhoto(context: viewContext, photo: photo)
    }
}

// MARK: - PhotoThumbnailWithBodyPart (部位バッジ付き)

struct PhotoThumbnailWithBodyPart: View {
    let photo: Photo
    let showBodyPart: Bool
    
    var body: some View {
        VStack {
            ZStack(alignment: .topTrailing) {
                // サムネイル画像
                if let thumbnailData = photo.thumbnail,
                   let nsImage = NSImage(data: thumbnailData),
                   let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                    Image(decorative: cgImage, scale: 1.0)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                // ✅ 部位バッジ（すべて表示時のみ）
                if showBodyPart, let bodyPart = photo.bodypart, !bodyPart.isEmpty {
                    Text(bodyPart)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(bodyPartColor(bodyPart))
                        .cornerRadius(4)
                        .padding(4)
                }
            }
        }
    }
    
    private func bodyPartColor(_ bodyPart: String) -> Color {
        switch bodyPart {
        case "胸":
            return .pink
        case "ドナー部位":
            return .orange
        default:
            return .gray
        }
    }
}

// MARK: - PhotoThumbnail (従来版・互換性のため残す)

struct PhotoThumbnail: View {
    let photo: Photo
    
    var body: some View {
        PhotoThumbnailWithBodyPart(photo: photo, showBodyPart: false)
    }
}
