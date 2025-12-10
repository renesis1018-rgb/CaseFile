import SwiftUI
import CoreData
import AppKit

struct BeforeAfterComparisonView: View {
    let photos: [Photo]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedAngle = "正面"
    @State private var beforePhotoIndex = 0
    @State private var afterPhotoIndex = 0
    @State private var comparisonCount = 2
    @State private var selectedTimings: [String] = []
    @State private var sliderValue: Double = 0
    @State private var availableTimings: [String] = []
    @State private var syncZoom = true
    @State private var zoomScale: CGFloat = 1.0
    
    let angles = ["正面", "右側面", "左側面", "右斜め", "左斜め", "その他"]
    
    var filteredPhotos: [String: [Photo]] {
        var result: [String: [Photo]] = [:]
        
        for timing in selectedTimings.prefix(comparisonCount) {
            let photosForTiming = photos.filter {
                $0.angle == selectedAngle && $0.timing == timing
            }
            result[timing] = photosForTiming
        }
        
        return result
    }
    
    var currentBeforePhoto: Photo? {
        guard selectedTimings.count > 0 else { return nil }
        let timing = selectedTimings[0]
        let photosForTiming = filteredPhotos[timing] ?? []
        guard !photosForTiming.isEmpty else { return nil }
        let index = min(beforePhotoIndex, photosForTiming.count - 1)
        return photosForTiming[index]
    }
    
    var currentAfterPhoto: Photo? {
        guard selectedTimings.count > 1 else { return nil }
        let timing = selectedTimings[1]
        let photosForTiming = filteredPhotos[timing] ?? []
        guard !photosForTiming.isEmpty else { return nil }
        let index = min(afterPhotoIndex, photosForTiming.count - 1)
        return photosForTiming[index]
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("📊 Before/After 比較")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                HStack {
                    Text("枚数:")
                        .fontWeight(.semibold)
                    
                    Picker("枚数", selection: $comparisonCount) {
                        Text("2枚").tag(2)
                        Text("3枚").tag(3)
                        Text("4枚").tag(4)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                    .onChange(of: comparisonCount) { _ in
                        updateSelectedTimings()
                    }
                }
                
                Spacer().frame(width: 20)
                
                Toggle("ズーム同期", isOn: $syncZoom)
                    .toggleStyle(.switch)
                
                Button("閉じる") {
                    dismiss()
                }
            }
            .padding()
            
            Divider()
            
            if availableTimings.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("選択した角度の写真がありません")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 15) {
                    HStack {
                        Text("角度:")
                            .fontWeight(.semibold)
                        
                        Picker("角度", selection: $selectedAngle) {
                            ForEach(angles, id: \.self) { angle in
                                Text(angle).tag(angle)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: selectedAngle) { _ in
                            updateAvailableTimings()
                        }
                        
                        Spacer()
                    }
                    
                    if selectedTimings.count >= comparisonCount {
                        HStack {
                            Text("比較:")
                                .fontWeight(.semibold)
                            
                            ForEach(0..<comparisonCount, id: \.self) { index in
                                if index > 0 {
                                    Text("vs")
                                        .foregroundColor(.secondary)
                                }
                                
                                Picker("時期\(index + 1)", selection: $selectedTimings[index]) {
                                    ForEach(availableTimings, id: \.self) { timing in
                                        Text(timing).tag(timing)
                                    }
                                }
                                .frame(width: 120)
                            }
                            
                            Spacer()
                        }
                    }
                    
                    if availableTimings.count > 1 {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text("タイムライン:")
                                    .fontWeight(.semibold)
                                
                                Text(getTimingFromSlider())
                                    .foregroundColor(.blue)
                                    .fontWeight(.bold)
                            }
                            
                            HStack {
                                Text("術前")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $sliderValue, in: 0...Double(max(availableTimings.count - 1, 0)), step: 1)
                                    .onChange(of: sliderValue) { _ in
                                        updateTimingFromSlider()
                                    }
                                
                                Text("最新")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                ForEach(Array(availableTimings.enumerated()), id: \.offset) { index, timing in
                                    VStack {
                                        Circle()
                                            .fill(Int(sliderValue) == index ? Color.blue : Color.gray)
                                            .frame(width: 8, height: 8)
                                        Text(timing)
                                            .font(.caption2)
                                            .foregroundColor(Int(sliderValue) == index ? .blue : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    HStack {
                        Text("ズーム:")
                            .fontWeight(.semibold)
                        
                        Button(action: { zoomOut() }) {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        .disabled(zoomScale <= 0.5)
                        
                        Text("\(Int(zoomScale * 100))%")
                            .frame(width: 60)
                        
                        Button(action: { zoomIn() }) {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .disabled(zoomScale >= 3.0)
                        
                        Button("リセット") {
                            zoomScale = 1.0
                        }
                        .disabled(zoomScale == 1.0)
                        
                        Spacer()
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    HStack(spacing: 20) {
                        if let beforePhoto = currentBeforePhoto {
                            ComparisonPhotoCard(
                                photo: beforePhoto,
                                timing: selectedTimings[0],
                                zoomScale: zoomScale,
                                photoIndex: beforePhotoIndex + 1,
                                totalPhotos: filteredPhotos[selectedTimings[0]]?.count ?? 0
                            )
                        }
                        
                        if comparisonCount > 1, selectedTimings.count > 1, let afterPhoto = currentAfterPhoto {
                            ComparisonPhotoCard(
                                photo: afterPhoto,
                                timing: selectedTimings[1],
                                zoomScale: zoomScale,
                                photoIndex: afterPhotoIndex + 1,
                                totalPhotos: filteredPhotos[selectedTimings[1]]?.count ?? 0
                            )
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 1400, height: 850)
        .focusable()
        .onKeyPress(.leftArrow) {
            if beforePhotoIndex > 0 {
                beforePhotoIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.rightArrow) {
            let maxIndex = (filteredPhotos[selectedTimings.first ?? ""]?.count ?? 1) - 1
            if beforePhotoIndex < maxIndex {
                beforePhotoIndex += 1
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            if afterPhotoIndex > 0 {
                afterPhotoIndex -= 1
            }
            return .handled
        }
        .onKeyPress(.downArrow) {
            let maxIndex = (filteredPhotos[selectedTimings.count > 1 ? selectedTimings[1] : ""]?.count ?? 1) - 1
            if afterPhotoIndex < maxIndex {
                afterPhotoIndex += 1
            }
            return .handled
        }
        .onAppear {
            updateAvailableTimings()
            beforePhotoIndex = 0
            afterPhotoIndex = 0
        }
    }
    
    private func updateAvailableTimings() {
        let timingsForAngle = photos
            .filter { $0.angle == selectedAngle }
            .compactMap { $0.timing }
        
        let uniqueTimings = Array(Set(timingsForAngle)).sorted { timing1, timing2 in
            timingOrder(timing1) < timingOrder(timing2)
        }
        
        availableTimings = uniqueTimings
        updateSelectedTimings()
        sliderValue = 0
        beforePhotoIndex = 0
        afterPhotoIndex = 0
    }
    
    private func updateSelectedTimings() {
        if selectedTimings.isEmpty || selectedTimings.count < comparisonCount {
            selectedTimings = []
            
            for i in 0..<comparisonCount {
                if i < availableTimings.count {
                    selectedTimings.append(availableTimings[i])
                } else {
                    selectedTimings.append(availableTimings.last ?? "術前")
                }
            }
        } else {
            selectedTimings = Array(selectedTimings.prefix(comparisonCount))
            
            while selectedTimings.count < comparisonCount {
                let nextIndex = min(selectedTimings.count, availableTimings.count - 1)
                selectedTimings.append(availableTimings[max(0, nextIndex)])
            }
        }
    }
    
    private func getTimingFromSlider() -> String {
        let index = Int(sliderValue)
        return availableTimings.indices.contains(index) ? availableTimings[index] : (availableTimings.first ?? "術前")
    }
    
    private func updateTimingFromSlider() {
        let timing = getTimingFromSlider()
        if selectedTimings.count > 1 {
            selectedTimings[1] = timing
        }
    }
    
    private func zoomIn() {
        withAnimation {
            zoomScale = min(zoomScale + 0.25, 3.0)
        }
    }
    
    private func zoomOut() {
        withAnimation {
            zoomScale = max(zoomScale - 0.25, 0.5)
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
            if timing.starts(with: "Day ") {
                let dayString = timing.replacingOccurrences(of: "Day ", with: "")
                if let days = Int(dayString) {
                    return 100 + days
                }
            }
            return 999
        }
    }
}

struct ComparisonPhotoCard: View {
    let photo: Photo
    let timing: String
    let zoomScale: CGFloat
    let photoIndex: Int
    let totalPhotos: Int
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(timing)
                    .font(.headline)
                
                Spacer()
                
                if totalPhotos > 1 {
                    Text("\(photoIndex) / \(totalPhotos)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
            
            if let imageData = photo.imageData,
               let nsImage = NSImage(data: imageData),
               let cgImage = nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil) {
                
                Image(decorative: cgImage, scale: 1.0)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 350, height: 350)
                    .scaleEffect(zoomScale)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue, lineWidth: 2)
                    )
                    .shadow(radius: 5)
                    .onDrag {
                        return createDragItem(imageData: imageData, photo: photo)
                    }
                
                VStack(alignment: .leading, spacing: 5) {
                    if let exifDate = photo.exifDate {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(.secondary)
                            Text("撮影: \(formatDate(exifDate))")
                                .font(.caption)
                        }
                    }
                    
                    if (photo.daysAfterSurgery?.int16Value ?? -1) >= 0 {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(.secondary)
                            Text("術後 \(photo.daysAfterSurgery)日")
                                .font(.caption)
                        }
                    }
                }
                .frame(maxWidth: 350, alignment: .leading)
                .padding(.horizontal)
                
            } else {
                VStack {
                    Image(systemName: "photo.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("写真なし")
                        .foregroundColor(.secondary)
                }
                .frame(width: 350, height: 350)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    private func createDragItem(imageData: Data, photo: Photo) -> NSItemProvider {
        let timing = photo.timing ?? "unknown"
        let angle = photo.angle ?? "unknown"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        let dateString = photo.exifDate.map { dateFormatter.string(from: $0) } ?? "nodate"
        
        let fileName = "photo_\(timing)_\(angle)_\(dateString).jpg"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try imageData.write(to: tempURL)
            return NSItemProvider(contentsOf: tempURL)!
        } catch {
            print("❌ ドラッグアイテム作成エラー: \(error)")
            return NSItemProvider()
        }
    }
}
