import SwiftUI
import CoreData

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: Patient.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Patient.patientId, ascending: true)]
    ) var patients: FetchedResults<Patient>
    
    // 検索・フィルタ用State
    @State private var searchText = ""
    @State private var showFilterPanel = false
    
    // フィルタ条件
    @State private var filterMinAge: String = ""
    @State private var filterMaxAge: String = ""
    @State private var filterMinBMI: String = ""
    @State private var filterMaxBMI: String = ""
    @State private var filterStartDate: Date? = nil
    @State private var filterEndDate: Date? = nil
    @State private var selectedCategories: Set<String> = []
    @State private var selectedLiposuctionAreas: Set<String> = []
    
    // ソート
    @State private var sortOption: SortOption = .idAsc
    
    // 新規患者追加
    @State private var showingAddPatient = false
    @State private var showingCSVImport = false
    
    enum SortOption: String, CaseIterable, Identifiable {
        case idAsc = "患者ID(昇順)"
        case idDesc = "患者ID(降順)"
        case ageDesc = "年齢(高い順)"
        case ageAsc = "年齢(低い順)"
        case nameAsc = "名前(昇順)"
        case nameDesc = "名前(降順)"
        case surgeryDateDesc = "手術日(新しい順)"
        case surgeryDateAsc = "手術日(古い順)"
        
        var id: String { self.rawValue }
    }
    
    // ✅ 手術カテゴリ候補（AddSurgeryViewに完全対応）
    let surgeryCategories = [
        "豊胸系",
        "脂肪注入 (PureGraft)",
        "脂肪注入 (Condense)",
        "脂肪注入 (ADRC)",
        "シリコン",
        "目元系",
        "埋没二重",
        "全切開二重",
        "眉下切開",
        "裏ハムラ",
        "切開ハムラ",
        "脂肪吸引",
        "美body",
        "Vaser",
        "Aquicell",
        "その他"
    ]
    
    // ✅ 脂肪吸引部位（AddSurgeryViewに対応）
    let liposuctionAreas: [(category: String, items: [String])] = [
        ("上肢", ["二の腕", "肩", "肩甲骨横"]),
        ("体幹", ["腹", "ウエスト", "腰", "背中上", "背中下"]),
        ("下肢", ["大腿", "臀部", "膝", "下腿", "足首"])
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // ✅ 検索バー + フィルタボタン
                HStack(spacing: 12) {
                    // 検索フィールド
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        TextField("患者ID・名前で検索", text: $searchText)
                            .textFieldStyle(PlainTextFieldStyle())
                    }
                    .padding(8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    
                    // フィルタボタン
                    Button(action: { showFilterPanel.toggle() }) {
                        HStack {
                            Image(systemName: showFilterPanel ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                            Text("フィルタ")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(showFilterPanel ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                        .foregroundColor(showFilterPanel ? .white : .primary)
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    // CSVインポートボタン
                    Button(action: { showingCSVImport = true }) {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                            Text("CSV")
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding()
                
                // ✅ フィルタパネル
                if showFilterPanel {
                    filterPanel
                }
                
                Divider()
                
                // ✅ 患者リスト
                if filteredAndSortedPatients.isEmpty {
                    emptyStateView
                } else {
                    patientList
                }
            }
            .navigationTitle("CaseFile")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddPatient = true }) {
                        Label("新規患者", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPatient) {
                AddPatientView(context: viewContext)
            }
            .sheet(isPresented: $showingCSVImport) {
                CSVImportView()
                    .environment(\.managedObjectContext, viewContext)
            }
        }
    }
    
    // MARK: - フィルタパネル
    var filterPanel: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 16) {
                // 年齢範囲
                HStack {
                    Text("年齢:")
                        .frame(width: 60, alignment: .leading)
                    TextField("最小", text: $filterMinAge)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("〜")
                    TextField("最大", text: $filterMaxAge)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Spacer()
                }
                
                // BMI範囲
                HStack {
                    Text("BMI:")
                        .frame(width: 60, alignment: .leading)
                    TextField("最小", text: $filterMinBMI)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Text("〜")
                    TextField("最大", text: $filterMaxBMI)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 80)
                    Spacer()
                }
                
                // 手術日範囲
                VStack(alignment: .leading, spacing: 8) {
                    Text("手術日:")
                    HStack {
                        DatePicker("開始日", selection: Binding(
                            get: { filterStartDate ?? Date() },
                            set: { filterStartDate = $0 }
                        ), displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        
                        Button("クリア") {
                            filterStartDate = nil
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    
                    HStack {
                        DatePicker("終了日", selection: Binding(
                            get: { filterEndDate ?? Date() },
                            set: { filterEndDate = $0 }
                        ), displayedComponents: .date)
                        .datePickerStyle(CompactDatePickerStyle())
                        .labelsHidden()
                        
                        Button("クリア") {
                            filterEndDate = nil
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                
                Divider()
                
                // 手術カテゴリ
                VStack(alignment: .leading, spacing: 8) {
                    Text("手術カテゴリ:")
                        .font(.headline)
                    
                    ForEach(surgeryCategories, id: \.self) { category in
                        categoryButton(category)
                    }
                }
                
                Divider()
                
                // ✅ 脂肪吸引部位フィルタ
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("脂肪吸引部位:")
                            .font(.headline)
                        
                        if !selectedLiposuctionAreas.isEmpty {
                            Button("クリア") {
                                selectedLiposuctionAreas.removeAll()
                            }
                            .font(.caption)
                            .buttonStyle(PlainButtonStyle())
                            .foregroundColor(.red)
                        }
                    }
                    
                    ForEach(liposuctionAreas, id: \.category) { area in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(area.category)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                                .padding(.top, 4)
                            
                            ForEach(area.items, id: \.self) { item in
                                liposuctionAreaButton(item)
                            }
                        }
                    }
                }
                
                Divider()
                
                // ソート
                HStack {
                    Text("並び替え:")
                        .frame(width: 80, alignment: .leading)
                    Picker("", selection: $sortOption) {
                        ForEach(SortOption.allCases) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 200)
                    Spacer()
                }
                
                Divider()
                
                // アクションボタン
                HStack {
                    Button("すべてクリア") {
                        clearFilters()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(8)
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Text("該当: \(filteredAndSortedPatients.count)件")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor).opacity(0.3))
        .cornerRadius(8)
        .padding(.horizontal)
        .frame(maxHeight: 400)
    }
    
    // カテゴリボタン
    func categoryButton(_ category: String) -> some View {
        Button(action: {
            if selectedCategories.contains(category) {
                selectedCategories.remove(category)
            } else {
                selectedCategories.insert(category)
            }
        }) {
            HStack {
                Image(systemName: selectedCategories.contains(category) ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(selectedCategories.contains(category) ? .accentColor : .gray)
                Text(category)
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(selectedCategories.contains(category) ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // ✅ 脂肪吸引部位ボタン
    func liposuctionAreaButton(_ area: String) -> some View {
        Button(action: {
            if selectedLiposuctionAreas.contains(area) {
                selectedLiposuctionAreas.remove(area)
            } else {
                selectedLiposuctionAreas.insert(area)
            }
        }) {
            HStack {
                Image(systemName: selectedLiposuctionAreas.contains(area) ? "checkmark.square.fill" : "square")
                    .foregroundColor(selectedLiposuctionAreas.contains(area) ? .green : .gray)
                Text(area)
                    .font(.caption)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(selectedLiposuctionAreas.contains(area) ? Color.green.opacity(0.1) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - 患者リスト
    var patientList: some View {
        List {
            ForEach(filteredAndSortedPatients, id: \.self) { patient in
                NavigationLink(destination: PatientDetailView(patient: patient)) {
                    PatientRowView(patient: patient)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    // MARK: - 空の状態
    var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            if patients.isEmpty {
                Text("患者データがありません")
                    .font(.headline)
                Text("「新規患者」ボタンから患者を追加してください")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("条件に一致する患者が見つかりません")
                    .font(.headline)
                Text("検索条件やフィルタを変更してください")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - フィルタ＆ソート処理
    var filteredAndSortedPatients: [Patient] {
        var result = patients.filter { patient in
            // 検索フィルタ
            if !searchText.isEmpty {
                let idMatch = patient.patientId?.localizedCaseInsensitiveContains(searchText) ?? false
                let nameMatch = patient.name?.localizedCaseInsensitiveContains(searchText) ?? false
                if !idMatch && !nameMatch {
                    return false
                }
            }
            
            // 年齢フィルタ
            if let minAge = Int(filterMinAge), let patientAge = patient.age {
                if Int(truncating: patientAge) < minAge {
                    return false
                }
            }
            if let maxAge = Int(filterMaxAge), let patientAge = patient.age {
                if Int(truncating: patientAge) > maxAge {
                    return false
                }
            }
            
            // BMIフィルタ（患者に紐づく手術からBMIを取得）
            if !filterMinBMI.isEmpty || !filterMaxBMI.isEmpty {
                guard let surgeries = patient.surgeries as? Set<Surgery>,
                      let surgery = surgeries.first,
                      let bmi = surgery.bmi else {
                    return false
                }
                
                if let minBMI = Double(filterMinBMI), bmi.doubleValue < minBMI {
                    return false
                }
                if let maxBMI = Double(filterMaxBMI), bmi.doubleValue > maxBMI {
                    return false
                }
            }
            
            // 手術カテゴリフィルタ（部分一致対応）
            if !selectedCategories.isEmpty {
                guard let surgeries = patient.surgeries as? Set<Surgery> else {
                    return false
                }
                let hasCategoryMatch = surgeries.contains { surgery in
                    guard let surgeryCategory = surgery.surgeryCategory,
                          let surgeryType = surgery.surgeryType else { return false }
                    
                    // 選択されたカテゴリのいずれかにマッチするかチェック
                    return selectedCategories.contains { selectedCategory in
                        // 完全一致または部分一致
                        surgeryCategory.contains(selectedCategory) ||
                        surgeryType.contains(selectedCategory) ||
                        selectedCategory.contains(surgeryCategory) ||
                        selectedCategory.contains(surgeryType)
                    }
                }
                if !hasCategoryMatch {
                    return false
                }
            }
            
            // ✅ 脂肪吸引部位フィルタ
            if !selectedLiposuctionAreas.isEmpty {
                guard let surgeries = patient.surgeries as? Set<Surgery> else {
                    return false
                }
                let hasLiposuctionAreaMatch = surgeries.contains { surgery in
                    // 脂肪吸引カテゴリかチェック
                    guard surgery.surgeryCategory == "脂肪吸引",
                          let donorSite = surgery.donorSite else { return false }
                    
                    // 選択された部位のいずれかがdonorSiteに含まれるかチェック
                    return selectedLiposuctionAreas.contains { selectedArea in
                        donorSite.contains(selectedArea)
                    }
                }
                if !hasLiposuctionAreaMatch {
                    return false
                }
            }
            
            // 手術日フィルタ
            if let startDate = filterStartDate, let endDate = filterEndDate {
                guard let surgeries = patient.surgeries as? Set<Surgery> else {
                    return false
                }
                let hasDateMatch = surgeries.contains { surgery in
                    guard let surgeryDate = surgery.surgeryDate else { return false }
                    return surgeryDate >= startDate && surgeryDate <= endDate
                }
                if !hasDateMatch {
                    return false
                }
            }
            
            return true
        }
        
        // ソート
        switch sortOption {
        case .idAsc:
            result.sort { ($0.patientId ?? "") < ($1.patientId ?? "") }
        case .idDesc:
            result.sort { ($0.patientId ?? "") > ($1.patientId ?? "") }
        case .ageDesc:
            result.sort { ($0.age?.intValue ?? 0) > ($1.age?.intValue ?? 0) }
        case .ageAsc:
            result.sort { ($0.age?.intValue ?? 0) < ($1.age?.intValue ?? 0) }
        case .nameAsc:
            result.sort { ($0.name ?? "") < ($1.name ?? "") }
        case .nameDesc:
            result.sort { ($0.name ?? "") > ($1.name ?? "") }
        case .surgeryDateDesc:
            result.sort { patient1, patient2 in
                let date1 = (patient1.surgeries as? Set<Surgery>)?.compactMap { $0.surgeryDate }.max() ?? Date.distantPast
                let date2 = (patient2.surgeries as? Set<Surgery>)?.compactMap { $0.surgeryDate }.max() ?? Date.distantPast
                return date1 > date2
            }
        case .surgeryDateAsc:
            result.sort { patient1, patient2 in
                let date1 = (patient1.surgeries as? Set<Surgery>)?.compactMap { $0.surgeryDate }.max() ?? Date.distantPast
                let date2 = (patient2.surgeries as? Set<Surgery>)?.compactMap { $0.surgeryDate }.max() ?? Date.distantPast
                return date1 < date2
            }
        }
        
        return result
    }
    
    // MARK: - ヘルパー
    func clearFilters() {
        searchText = ""
        filterMinAge = ""
        filterMaxAge = ""
        filterMinBMI = ""
        filterMaxBMI = ""
        filterStartDate = nil
        filterEndDate = nil
        selectedCategories.removeAll()
        selectedLiposuctionAreas.removeAll()
        sortOption = .idAsc
    }
}

// MARK: - 患者行ビュー
struct PatientRowView: View {
    let patient: Patient
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(patient.name ?? "名前なし")
                    .font(.headline)
                HStack(spacing: 12) {
                    Label(patient.patientId ?? "ID未設定", systemImage: "number")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let age = patient.age {
                        Label("\(age)歳", systemImage: "person")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // BMIは手術情報から取得
                    if let surgeries = patient.surgeries as? Set<Surgery>,
                       let surgery = surgeries.first,
                       let bmi = surgery.bmi {
                        Label(String(format: "BMI %.1f", bmi.doubleValue), systemImage: "figure.stand")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // ✅ 最新の手術日を表示（修正）
                    if let surgeries = patient.surgeries as? Set<Surgery>,
                       let latestSurgeryDate = surgeries.compactMap({ $0.surgeryDate }).max() {
                        let dateString = formatDate(latestSurgeryDate)
                        Label(dateString, systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            
            // 手術数表示
            if let surgeries = patient.surgeries as? Set<Surgery>, !surgeries.isEmpty {
                VStack(alignment: .trailing) {
                    Text("\(surgeries.count)件")
                        .font(.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    // ✅ 日付フォーマット用のヘルパー関数
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
