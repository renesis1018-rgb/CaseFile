//
//  BeforeAfterComparisonView.swift
//  CaseFile
//
//  Before/After比較ビュー - 上下キー=Before切替、左右キー=After切替
//

import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct BeforeAfterComparisonView: View {
    let photos: [Photo]
    let isFatGraft: Bool
    @State private var bodyPartFilter: BodyPartFilter
    
    @State private var selectedAngle: String
    @State private var numberOfPhotos: Int = 2
    @State private var beforePhotoIndex: Int = 0  // ✅ Before写真のインデックス
    @State private var afterStartIndex: Int = 1   // ✅ After写真群の開始インデックス
    @State private var zoomScale: CGFloat = 1.0
    @State private var syncZoom: Bool = true
    @State private var keyMonitor: Any?
    
    @Environment(\.dismiss) private var dismiss
    
    enum BodyPartFilter: String, CaseIterable, Identifiable {
        case all = "すべて"
        case chest = "胸"
        case donor = "ドナー部位"
        case unspecified = "未分類"
        
        var id: String { rawValue }
    }
    
    private var filteredPhotos: [Photo] {
        switch bodyPartFilter {
        case .all:
            return photos
        case .chest:
            return photos.filter { $0.bodypart == "胸" }
        case .donor:
            return photos.filter { $0.bodypart == "ドナー部位" }
        case .unspecified:
            return photos.filter { $0.bodypart == nil || $0.bodypart?.isEmpty == true }
        }
    }
    
    init(photos: [Photo], isFatGraft: Bool = false, initialBodyPartFilter: PhotoManagementView.BodyPartFilter = .all) {
        self.photos = photos
        self.isFatGraft = isFatGraft
        
        let filter: BodyPartFilter
        switch initialBodyPartFilter {
        case .all:
            filter = .all
        case .chest:
            filter = .chest
        case .donor:
            filter = .donor
        case .unspecified:
            filter = .unspecified
        }
        _bodyPartFilter = State(initialValue: filter)
        
        let angles = Set(photos.compactMap { $0.angle }).sorted()
        _selectedAngle = State(initialValue: angles.first ?? "正面")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()
            
            if filteredPhotos.isEmpty {
                emptyStateView
            } else if photosForSelectedAngle.isEmpty {
                noPhotosForAngleView
            } else {
                VStack(spacing: 0) {
                    controlPanel
                    Divider()
                    comparisonView
                    
                    // スライダーは不要（キーボード操作のみ）
                    navigationHint
                }
            }
        }
        .frame(minWidth: 900, minHeight: 700)
        .onAppear {
            setupKeyMonitor()
        }
        .onDisappear {
            removeKeyMonitor()
        }
        .onChange(of: selectedAngle) { _, _ in
            beforePhotoIndex = 0
            afterStartIndex = 1
        }
        .onChange(of: numberOfPhotos) { _, _ in
            adjustAfterIndex()
        }
        .onChange(of: bodyPartFilter) { _, _ in
            beforePhotoIndex = 0
            afterStartIndex = 1
        }
    }
    
    // MARK: - Keyboard Monitoring
    
    private func setupKeyMonitor() {
        let localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return self.handleKeyEvent(event)
        }
        
        let globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
            _ = self.handleKeyEvent(event)
        }
        
        keyMonitor = (localMonitor, globalMonitor)
    }
    
    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        switch event.keyCode {
        case 126: // ↑ Up Arrow
            DispatchQueue.main.async {
                self.moveBeforePrevious()
            }
            return nil
        case 125: // ↓ Down Arrow
            DispatchQueue.main.async {
                self.moveBeforeNext()
            }
            return nil
        case 123: // ← Left Arrow
            DispatchQueue.main.async {
                self.moveAfterPrevious()
            }
            return nil
        case 124: // → Right Arrow
            DispatchQueue.main.async {
                self.moveAfterNext()
            }
            return nil
        case 53: // Escape
            DispatchQueue.main.async {
                self.dismiss()
            }
            return nil
        default:
            return event
        }
    }
    
    private func removeKeyMonitor() {
        if let monitors = keyMonitor as? (Any, Any) {
            NSEvent.removeMonitor(monitors.0)
            NSEvent.removeMonitor(monitors.1)
            keyMonitor = nil
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("📊 Before/After 比較")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("(\(photosForSelectedAngle.count)枚)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if isFatGraft {
                Picker("部位", selection: $bodyPartFilter) {
                    ForEach(BodyPartFilter.allCases) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 300)
            }
            
            Button("閉じる") {
                dismiss()
            }
            .keyboardShortcut(.cancelAction)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
    }
    
    // MARK: - Empty State
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text(bodyPartFilter == .all ? "写真がありません" : "\(bodyPartFilter.rawValue)の写真がありません")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var noPhotosForAngleView: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("この角度の写真がありません")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("別の角度を選択してください")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Control Panel
    
    private var controlPanel: some View {
        HStack(spacing: 20) {
            HStack {
                Text("角度:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $selectedAngle) {
                    ForEach(availableAngles, id: \.self) { angle in
                        Text(angle).tag(angle)
                    }
                }
                .frame(width: 150)
            }
            
            Divider()
                .frame(height: 20)
            
            HStack {
                Text("比較枚数:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Picker("", selection: $numberOfPhotos) {
                    Text("2枚").tag(2)
                    Text("3枚").tag(3)
                    Text("4枚").tag(4)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }
            
            Divider()
                .frame(height: 20)
            
            Toggle("ズーム同期", isOn: $syncZoom)
                .toggleStyle(.switch)
            
            Spacer()
            
            HStack(spacing: 8) {
                Button(action: { zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .disabled(zoomScale <= 0.5)
                
                Text("\(Int(zoomScale * 100))%")
                    .font(.caption)
                    .frame(width: 50)
                
                Button(action: { zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .disabled(zoomScale >= 3.0)
                
                Button(action: { resetZoom() }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .help("ズームリセット")
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }
    
    // MARK: - Comparison View
    
    private var comparisonView: some View {
        GeometryReader { geometry in
            HStack(spacing: 10) {
                ForEach(Array(displayedPhotos.enumerated()), id: \.offset) { index, photo in
                    ComparisonPhotoCard(
                        photo: photo,
                        timing: photo.timing ?? "",
                        zoomScale: zoomScale,
                        width: (geometry.size.width - CGFloat(numberOfPhotos - 1) * 10) / CGFloat(numberOfPhotos),
                        showBodyPart: isFatGraft && bodyPartFilter == .all,
                        label: index == 0 ? "Before" : "After"
                    )
                }
            }
            .padding()
        }
    }
    
    // MARK: - Navigation Hint
    
    private var navigationHint: some View {
        HStack {
            Text("↑↓ Before切替")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("Before: \(beforePhotoIndex + 1) / \(photosForSelectedAngle.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("After: \(afterStartIndex + 1)~\(min(afterStartIndex + numberOfPhotos - 1, photosForSelectedAngle.count)) / \(photosForSelectedAngle.count)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text("←→ After切替")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }
    
    // MARK: - Helper Properties
    
    private var availableAngles: [String] {
        let angles = Set(filteredPhotos.compactMap { $0.angle })
        return angles.sorted { angleOrder($0) < angleOrder($1) }
    }
    
    private var photosForSelectedAngle: [Photo] {
        filteredPhotos.filter { $0.angle == selectedAngle }
            .sorted { timingOrder($0.timing ?? "") < timingOrder($1.timing ?? "") }
    }
    
    private var displayedPhotos: [Photo] {
        guard !photosForSelectedAngle.isEmpty else { return [] }
        
        var result: [Photo] = []
        
        // Before写真（1枚目）
        let beforeIndex = min(beforePhotoIndex, photosForSelectedAngle.count - 1)
        result.append(photosForSelectedAngle[beforeIndex])
        
        // After写真（2枚目以降）
        let afterCount = numberOfPhotos - 1
        let afterStart = min(afterStartIndex, photosForSelectedAngle.count - 1)
        
        for i in 0..<afterCount {
            let index = min(afterStart + i, photosForSelectedAngle.count - 1)
            result.append(photosForSelectedAngle[index])
        }
        
        return result
    }
    
    // MARK: - Helper Functions
    
    private func adjustAfterIndex() {
        let maxAfterStart = max(0, photosForSelectedAngle.count - 1)
        afterStartIndex = min(afterStartIndex, maxAfterStart)
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
            if timing.starts(with: "Day ") {
                let dayString = timing.replacingOccurrences(of: "Day ", with: "")
                if let days = Int(dayString) {
                    return 100 + days
                }
            }
            return 999
        }
    }
    
    private func angleOrder(_ angle: String) -> Int {
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
    
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = min(zoomScale + 0.25, 3.0)
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = max(zoomScale - 0.25, 0.5)
        }
    }
    
    private func resetZoom() {
        withAnimation(.easeInOut(duration: 0.2)) {
            zoomScale = 1.0
        }
    }
    
    // ✅ Before写真のナビゲーション
    private func moveBeforePrevious() {
        if beforePhotoIndex > 0 {
            beforePhotoIndex -= 1
            print("⬆️ Before前へ: \(beforePhotoIndex + 1) / \(photosForSelectedAngle.count)")
        }
    }
    
    private func moveBeforeNext() {
        if beforePhotoIndex < photosForSelectedAngle.count - 1 {
            beforePhotoIndex += 1
            print("⬇️ Before次へ: \(beforePhotoIndex + 1) / \(photosForSelectedAngle.count)")
        }
    }
    
    // ✅ After写真のナビゲーション
    private func moveAfterPrevious() {
        if afterStartIndex > 0 {
            afterStartIndex -= 1
            print("⬅️ After前へ: \(afterStartIndex + 1) / \(photosForSelectedAngle.count)")
        }
    }
    
    private func moveAfterNext() {
        let maxAfterStart = max(0, photosForSelectedAngle.count - 1)
        if afterStartIndex < maxAfterStart {
            afterStartIndex += 1
            print("➡️ After次へ: \(afterStartIndex + 1) / \(photosForSelectedAngle.count)")
        }
    }
}

// MARK: - Comparison Photo Card

struct ComparisonPhotoCard: View {
    let photo: Photo
    let timing: String
    let zoomScale: CGFloat
    let width: CGFloat
    let showBodyPart: Bool
    let label: String  // ✅ "Before" or "After"
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                // ✅ Before/Afterラベル
                Text(label)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(label == "Before" ? .blue : .orange)
                
                Text(timing)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if showBodyPart, let bodyPart = photo.bodypart, !bodyPart.isEmpty {
                    Text(bodyPart)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(bodyPartColor(bodyPart))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                if let date = photo.exifDate {
                    Text(formatDate(date))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
            
            if let imageData = photo.imageData,
               let nsImage = NSImage(data: imageData),
               let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    Image(decorative: cgImage, scale: 1.0)
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(zoomScale)
                        .frame(width: width - 16)
                }
                .frame(width: width - 16)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
                .onDrag {
                    if let imageData = photo.imageData {
                        return NSItemProvider(object: NSImage(data: imageData) ?? NSImage())
                    }
                    return NSItemProvider()
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: width - 16, height: 400)
                    .overlay(
                        Image(systemName: "photo")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                    )
            }
            
            HStack {
                Text(photo.angle ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let days = photo.daysAfterSurgery {
                    Text("術後\(days)日")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: width)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(12)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}
