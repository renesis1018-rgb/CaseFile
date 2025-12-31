import SwiftUI
import CoreData
import AppKit
import UniformTypeIdentifiers

struct PhotoUploadView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let surgery: Surgery
    
    @State private var selectedImages: [NSImage] = []
    @State private var uploadImages: [UploadImage] = []
    @State private var isUploading = false
    @State private var uploadProgress: Double = 0
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isDragging = false
    @State private var selectedBodyPart: BodyPart = .chest
    @State private var selectedImageId: UUID?  // 選択中の画像
    @FocusState private var isKeyboardFocused: Bool  // キーボード操作用
    
    // 手術日を取得
    private var surgeryDate: Date {
        surgery.surgeryDate ?? Date()
    }
    
    // 脂肪注入かどうかを判定
    private var isFatGraft: Bool {
        let procedure = surgery.procedure?.lowercased() ?? ""
        return procedure.contains("脂肪注入") || procedure.contains("脂肪豊胸") || procedure.contains("fat graft")
    }
    
    // 部位の定義
    enum BodyPart: String, CaseIterable, Identifiable {
        case chest = "胸"
        case donor = "ドナー部位"
        
        var id: String { rawValue }
        
        var angles: [String] {
            switch self {
            case .chest:
                return ["正面", "右側面", "右斜め", "左斜め", "左側面"]
            case .donor:
                return ["正面", "右側面", "右斜め", "左斜め", "左側面", "左斜め後ろ", "背面", "右斜め後ろ"]
            }
        }
        
        var badgeColor: Color {
            switch self {
            case .chest: return .pink
            case .donor: return .orange
            }
        }
    }
    
    // アップロード用の画像データ
    struct UploadImage: Identifiable {
        let id = UUID()
        let image: NSImage
        var angle: String
        var bodyPart: BodyPart = .chest
        var exifDate: Date?  // ← EXIF日付を保持
        var timing: String?  // ← 推定された時期を保持
        var daysAfterSurgery: Int?  // ← 経過日数を保持
    }
    
    // 通常の角度リスト（脂肪注入以外）
    private let standardAngles = ["正面", "右側面", "右斜め", "左斜め", "左側面", "左斜め後ろ", "背面", "右斜め後ろ"]
    
    var body: some View {
        VStack(spacing: 20) {
            // タイトル
            Text("写真をアップロード")
                .font(.title2)
                .fontWeight(.bold)
            
            // 患者情報と手術情報
            VStack(alignment: .leading, spacing: 8) {
                if let patient = surgery.patient {
                    Text("患者: \(patient.name ?? "不明") (ID: \(patient.patientId ?? ""))")
                        .font(.headline)
                }
                Text("手術日: \(surgeryDate, formatter: dateFormatter)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text("術式: \(surgery.procedure ?? "")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if isFatGraft {
                    Text("💡 脂肪注入: 胸の写真とドナー部位の写真を分けて管理できます")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            // 部位選択タブ（脂肪注入の場合のみ表示）
            if isFatGraft && !uploadImages.isEmpty {
                Picker("部位", selection: $selectedBodyPart) {
                    ForEach(BodyPart.allCases) { bodyPart in
                        Text(bodyPart.rawValue).tag(bodyPart)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
            }
            
            ScrollView {
                VStack(spacing: 20) {
                    // ドラッグ&ドロップゾーン
                    if uploadImages.isEmpty {
                        // 大きなドロップゾーン
                        VStack(spacing: 20) {
                            DropZone(isDragging: $isDragging) {
                                handleDroppedFiles($0)
                            }
                            
                            Button(action: selectImages) {
                                Label("ファイルを選択", systemImage: "photo.fill.on.rectangle.fill")
                                    .font(.headline)
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                        }
                        .padding()
                    } else {
                        // ミニドロップゾーン
                        DropZone(isDragging: $isDragging, isCompact: true) {
                            handleDroppedFiles($0)
                        }
                        .padding(.horizontal)
                        .onTapGesture {
                            selectImages()
                        }
                        
                        // キーボード操作のヒント
                        HStack {
                            Image(systemName: "keyboard")
                                .foregroundColor(.secondary)
                            if isFatGraft {
                                Text("キーボード操作: 数字キー 1-8 で角度割り当て、Tab で部位切替（表示タブは維持）、Space で次の写真へ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("キーボード操作: 数字キー 1-8 で角度割り当て、Space で次の写真へ")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // 選択された写真のリスト
                        let filteredImages = isFatGraft ? uploadImages.filter { $0.bodyPart == selectedBodyPart } : uploadImages
                        
                        if filteredImages.isEmpty && isFatGraft {
                            VStack(spacing: 12) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                                Text("\(selectedBodyPart.rawValue)の写真はまだありません")
                                    .foregroundColor(.secondary)
                                Text("上のドロップゾーンから写真を追加してください")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150))], spacing: 16) {
                                ForEach(filteredImages) { uploadImage in
                                    ImageThumbnailCard(
                                        uploadImage: uploadImage,
                                        isSelected: selectedImageId == uploadImage.id,
                                        isFatGraft: isFatGraft,
                                        availableAngles: isFatGraft ? uploadImage.bodyPart.angles : standardAngles,
                                        onSelect: {
                                            selectedImageId = uploadImage.id
                                            isKeyboardFocused = true
                                        },
                                        onAngleChange: { newAngle in
                                            if let index = uploadImages.firstIndex(where: { $0.id == uploadImage.id }) {
                                                uploadImages[index].angle = newAngle
                                            }
                                        },
                                        onBodyPartChange: {
                                            if let index = uploadImages.firstIndex(where: { $0.id == uploadImage.id }) {
                                                let newBodyPart: BodyPart = uploadImages[index].bodyPart == .chest ? .donor : .chest
                                                uploadImages[index].bodyPart = newBodyPart
                                                uploadImages[index].angle = newBodyPart.angles.first ?? "正面"
                                            }
                                        },
                                        onRemove: {
                                            removeImage(uploadImage)
                                        }
                                    )
                                }
                            }
                            .padding()
                            .focusable()
                            .focused($isKeyboardFocused)
                            .onKeyPress { keyPress in
                                handleKeyPress(keyPress)
                            }
                        }
                    }
                }
            }
            
            // アップロード進行状況
            if isUploading {
                VStack(spacing: 8) {
                    ProgressView(value: uploadProgress)
                    Text("アップロード中... \(Int(uploadProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // ボタン
            HStack(spacing: 16) {
                Button("キャンセル") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                
                Button("写真を保存 (\(uploadImages.count)枚)") {
                    uploadPhotos()
                }
                .buttonStyle(.borderedProminent)
                .disabled(uploadImages.isEmpty || isUploading)
            }
        }
        .padding()
        .frame(width: 900, height: 700)
        .alert("通知", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    // キーボード操作の処理
    private func handleKeyPress(_ keyPress: KeyPress) -> KeyPress.Result {
        guard let selectedId = selectedImageId,
              let selectedIndex = uploadImages.firstIndex(where: { $0.id == selectedId }) else {
            return .ignored
        }
        
        let availableAngles = isFatGraft ? uploadImages[selectedIndex].bodyPart.angles : standardAngles
        
        // 数字キーで角度を割り当て (1-8)
        if let number = Int(keyPress.characters), number >= 1, number <= availableAngles.count {
            uploadImages[selectedIndex].angle = availableAngles[number - 1]
            
            // 自動で次の写真に移動
            let filteredImages = isFatGraft ? uploadImages.filter { $0.bodyPart == selectedBodyPart } : uploadImages
            if let currentFilteredIndex = filteredImages.firstIndex(where: { $0.id == selectedId }),
               currentFilteredIndex + 1 < filteredImages.count {
                selectedImageId = filteredImages[currentFilteredIndex + 1].id
            }
            
            return .handled
        }
        
        // Tabキーで部位を切り替え（脂肪注入の場合のみ）
        if keyPress.key == .tab && isFatGraft {
            let filteredImagesBeforeChange = uploadImages.filter { $0.bodyPart == selectedBodyPart }
            let nextImageId: UUID? = {
                if let currentFilteredIndex = filteredImagesBeforeChange.firstIndex(where: { $0.id == selectedId }) {
                    if currentFilteredIndex + 1 < filteredImagesBeforeChange.count {
                        return filteredImagesBeforeChange[currentFilteredIndex + 1].id
                    } else {
                        return filteredImagesBeforeChange.first?.id
                    }
                }
                return nil
            }()
            
            let currentBodyPart = uploadImages[selectedIndex].bodyPart
            let newBodyPart: BodyPart = currentBodyPart == .chest ? .donor : .chest
            uploadImages[selectedIndex].bodyPart = newBodyPart
            uploadImages[selectedIndex].angle = newBodyPart.angles.first ?? "正面"
            
            if let nextId = nextImageId {
                selectedImageId = nextId
            }
            
            return .handled
        }
        
        // Spaceキーで次の写真へ
        if keyPress.key == .space {
            let filteredImages = isFatGraft ? uploadImages.filter { $0.bodyPart == selectedBodyPart } : uploadImages
            if let currentIndex = filteredImages.firstIndex(where: { $0.id == selectedId }),
               currentIndex + 1 < filteredImages.count {
                selectedImageId = filteredImages[currentIndex + 1].id
            } else if !filteredImages.isEmpty {
                selectedImageId = filteredImages.first?.id
            }
            return .handled
        }
        
        return .ignored
    }
    
    // ドロップされたファイルを処理（EXIF日付抽出を追加）
    private func handleDroppedFiles(_ urls: [URL]) {
        let newImages = urls.compactMap { url -> (NSImage, Data)? in
            guard let data = try? Data(contentsOf: url),
                  let image = NSImage(data: data) else { return nil }
            return (image, data)
        }
        
        // 最大100枚に制限
        let remainingSlots = 100 - uploadImages.count
        let imagesToAdd = Array(newImages.prefix(remainingSlots))
        
        let currentBodyPart = isFatGraft ? selectedBodyPart : .chest
        let angles = isFatGraft ? currentBodyPart.angles : standardAngles
        
        for (image, imageData) in imagesToAdd {
            // EXIF日付を抽出
            let exifDate = PhotoManager.shared.extractEXIFDate(from: imageData)
            
            // 経過日数を計算
            let daysAfter: Int?
            let timing: String?
            
            if let exifDate = exifDate {
                let days = PhotoManager.shared.calculateDaysAfterSurgery(surgeryDate: surgeryDate, photoDate: exifDate)
                daysAfter = days
                timing = PhotoManager.shared.estimateTiming(from: days)
                print("📅 EXIF検出: \(exifDate) → 経過\(days)日 → \(timing ?? "不明")")
            } else {
                daysAfter = nil
                timing = "術前"
                print("⚠️ EXIF日付なし → 術前")
            }
            
            let uploadImage = UploadImage(
                image: image,
                angle: angles.first ?? "正面",
                bodyPart: currentBodyPart,
                exifDate: exifDate,
                timing: timing,
                daysAfterSurgery: daysAfter
            )
            uploadImages.append(uploadImage)
        }
        
        if newImages.count > remainingSlots {
            alertMessage = "最大100枚までアップロード可能です。\(remainingSlots)枚のみ追加されました。"
            showAlert = true
        }
        
        print("✅ \(imagesToAdd.count)枚の写真をドロップで追加しました")
    }
    
    // 画像選択ダイアログ
    private func selectImages() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        panel.message = "アップロードする写真を選択してください（最大100枚）"
        
        panel.begin { response in
            if response == .OK {
                handleDroppedFiles(panel.urls)
            }
        }
    }
    
    // 画像を削除
    private func removeImage(_ uploadImage: UploadImage) {
        uploadImages.removeAll { $0.id == uploadImage.id }
        if selectedImageId == uploadImage.id {
            selectedImageId = nil
        }
    }
    
    // 写真をアップロード（修正：事前に計算した値を使用）
    private func uploadPhotos() {
        isUploading = true
        uploadProgress = 0
        
        DispatchQueue.global(qos: .userInitiated).async {
            let totalImages = uploadImages.count
            
            for (index, uploadImage) in uploadImages.enumerated() {
                guard let tiffData = uploadImage.image.tiffRepresentation,
                      let bitmapRep = NSBitmapImageRep(data: tiffData),
                      let imageData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: 0.8]) else {
                    continue
                }
                
                DispatchQueue.main.async {
                    // ⭐ 重要: 事前に計算済みの値をそのまま使用
                    let photo = Photo(context: viewContext)
                    photo.id = UUID()
                    photo.imageData = imageData
                    photo.angle = uploadImage.angle
                    photo.uploadDate = Date()
                    photo.surgery = surgery
                    photo.bodypart = isFatGraft ? uploadImage.bodyPart.rawValue : nil
                    
                    // EXIF日付と経過日数を設定
                    if let exifDate = uploadImage.exifDate {
                        photo.exifDate = exifDate
                        photo.daysAfterSurgery = NSNumber(value: uploadImage.daysAfterSurgery ?? 0)
                        photo.timing = uploadImage.timing ?? "術前"
                    } else {
                        photo.timing = "術前"
                        photo.daysAfterSurgery = NSNumber(value: 0)
                    }
                    
                    // サムネイル生成
                    if let thumbnailData = PhotoManager.shared.generateThumbnail(from: imageData) {
                        photo.thumbnail = thumbnailData
                    }
                    
                    do {
                        try viewContext.save()
                        print("✅ 写真保存成功: \(photo.timing ?? "nil") / \(photo.angle ?? "nil") / \(photo.bodypart ?? "未設定")")
                    } catch {
                        print("❌ 写真保存失敗: \(error)")
                    }
                    
                    uploadProgress = Double(index + 1) / Double(totalImages)
                }
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isUploading = false
                alertMessage = "\(totalImages)枚の写真をアップロードしました"
                showAlert = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter
    }
}

// ドロップゾーンコンポーネント
struct DropZone: View {
    @Binding var isDragging: Bool
    let isCompact: Bool
    let onDrop: ([URL]) -> Void
    
    init(isDragging: Binding<Bool>, isCompact: Bool = false, onDrop: @escaping ([URL]) -> Void) {
        self._isDragging = isDragging
        self.isCompact = isCompact
        self.onDrop = onDrop
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: isCompact ? 8 : 12)
                .stroke(isDragging ? Color.blue : Color.gray.opacity(isCompact ? 0.3 : 0.5), 
                       style: StrokeStyle(lineWidth: isCompact ? 2 : 3, dash: isCompact ? [5] : [10]))
                .background(
                    RoundedRectangle(cornerRadius: isCompact ? 8 : 12)
                        .fill(isDragging ? Color.blue.opacity(0.1) : Color.gray.opacity(isCompact ? 0 : 0.05))
                )
                .frame(height: isCompact ? 60 : 200)
            
            if isCompact {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(isDragging ? .blue : .gray)
                    Text(isDragging ? "ドロップして追加" : "写真を追加（ドラッグ&ドロップまたはクリック）")
                        .foregroundColor(isDragging ? .blue : .secondary)
                }
                .padding(.vertical, 12)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: isDragging ? "photo.fill.on.rectangle.fill" : "photo.on.rectangle.angled")
                        .font(.system(size: 50))
                        .foregroundColor(isDragging ? .blue : .gray)
                    
                    Text(isDragging ? "ドロップして追加" : "ここに写真をドラッグ&ドロップ")
                        .font(.headline)
                        .foregroundColor(isDragging ? .blue : .secondary)
                    
                    Text("または")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onDrop(of: [UTType.fileURL], isTargeted: $isDragging) { providers in
            loadDroppedFiles(providers: providers)
            return true
        }
    }
    
    private func loadDroppedFiles(providers: [NSItemProvider]) {
        var urls: [URL] = []
        let group = DispatchGroup()
        
        for provider in providers {
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, error in
                defer { group.leave() }
                if let url = url {
                    DispatchQueue.main.async {
                        urls.append(url)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if !urls.isEmpty {
                onDrop(urls)
            }
        }
    }
}

// 画像サムネイルカード
struct ImageThumbnailCard: View {
    let uploadImage: PhotoUploadView.UploadImage
    let isSelected: Bool
    let isFatGraft: Bool
    let availableAngles: [String]
    let onSelect: () -> Void
    let onAngleChange: (String) -> Void
    let onBodyPartChange: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Image(nsImage: uploadImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 150, height: 150)
                    .clipped()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
                    .onTapGesture {
                        onSelect()
                    }
                
                // 部位バッジ（脂肪注入の場合のみ）
                if isFatGraft {
                    Text(uploadImage.bodyPart.rawValue)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(uploadImage.bodyPart.badgeColor)
                        .cornerRadius(4)
                        .padding(4)
                }
                
                // 削除ボタン
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .background(Circle().fill(Color.white))
                }
                .buttonStyle(.plain)
                .padding(8)
                .offset(x: 0, y: isFatGraft ? 24 : 0)
            }
            
            // 時期表示（デバッグ用）
            if let timing = uploadImage.timing {
                Text(timing)
                    .font(.caption2)
                    .foregroundColor(timing == "術前" ? .orange : .green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
            }
            
            // 角度選択（クリック方式）
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 4) {
                ForEach(Array(availableAngles.enumerated()), id: \.offset) { index, angle in
                    Button(action: {
                        onAngleChange(angle)
                        onSelect()
                    }) {
                        VStack(spacing: 2) {
                            Text("\(index + 1)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(angle)
                                .font(.caption)
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(uploadImage.angle == angle ? Color.blue : Color.gray.opacity(0.2))
                        .foregroundColor(uploadImage.angle == angle ? .white : .primary)
                        .cornerRadius(4)
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 150)
            
            // 部位変更ボタン（脂肪注入の場合のみ）
            if isFatGraft {
                Button(action: onBodyPartChange) {
                    Label(uploadImage.bodyPart == .chest ? "→ ドナー部位へ" : "→ 胸へ", 
                          systemImage: "arrow.left.arrow.right")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
    }
}
