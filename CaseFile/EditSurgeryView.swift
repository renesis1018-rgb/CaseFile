//
//  EditSurgeryView.swift
//  CaseFile
//
//  手術情報編集画面（Phase 3改良版 + 脂肪吸引部位編集対応）
//

import SwiftUI
import CoreData

struct EditSurgeryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var surgery: Surgery
    let context: NSManagedObjectContext
    
    // MARK: - 基本情報（読み取り専用）
    private var surgeryDate: Date { surgery.surgeryDate ?? Date() }
    private var surgeryCategory: String { surgery.surgeryCategory ?? "" }
    private var surgeryType: String { surgery.surgeryType ?? "" }
    
    // MARK: - 患者基礎情報
    @State private var height: String = ""
    @State private var bodyWeight: String = ""
    @State private var bmi: String = ""
    
    // MARK: - 患者情報（豊胸系）
    @State private var smokingHistory: String = ""
    @State private var breastfeedingHistory: String = ""
    @State private var numberOfProcedures: String = ""
    
    // MARK: - 術前測定値（豊胸系）
    @State private var preOpVectraR: String = ""
    @State private var preOpVectraL: String = ""
    @State private var nacImfRight: String = ""
    @State private var nacImfLeft: String = ""
    @State private var skinThicknessRight: String = ""
    @State private var skinThicknessLeft: String = ""
    
    // MARK: - 層別注入量（脂肪注入）
    @State private var donorSite: String = ""
    @State private var donorSiteOther: String = ""
    @State private var subcutaneousRight: String = ""
    @State private var subcutaneousLeft: String = ""
    @State private var subglandularRight: String = ""
    @State private var subglandularLeft: String = ""
    @State private var submuscularRight: String = ""
    @State private var submuscularLeft: String = ""
    @State private var decolletRight: String = ""
    @State private var decolletLeft: String = ""
    
    // MARK: - シリコン豊胸
    @State private var implantSizeR: String = ""
    @State private var implantSizeL: String = ""
    @State private var implantManufacturer: String = ""
    @State private var incisionSite: String = ""
    @State private var insertionPlane: String = ""
    
    // MARK: - 脂肪吸引（✅ 修正: 部位選択を配列で管理）
    @State private var selectedLiposuctionAreas: Set<String> = []
    @State private var liposuctionVolume: String = ""
    @State private var aquicellUsed: Bool = false
    @State private var vaserUsed: Bool = false
    
    // ✅ 脂肪吸引部位リスト（AddSurgeryViewと同じ）
    let liposuctionAreas: [(category: String, items: [String])] = [
        ("上肢", ["二の腕", "肩", "肩甲骨横"]),
        ("体幹", ["腹", "ウエスト", "腰", "背中上", "背中下"]),
        ("下肢", ["大腿", "臀部", "膝", "下腿", "足首"])
    ]
    
    // MARK: - その他
    @State private var notes: String = ""
    
    // MARK: - UI状態
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // 基本情報（読み取り専用）
                    basicInfoSection
                    
                    // 患者基礎情報
                    patientBasicInfoSection
                    
                    // カテゴリー別詳細情報
                    if surgeryCategory == "豊胸系" {
                        breastAugmentationSection
                        
                        if surgeryType.contains("脂肪注入") {
                            fatInjectionSection
                        } else if surgeryType.contains("シリコン") {
                            siliconeSection
                        }
                    } else if surgeryCategory == "脂肪吸引" {
                        liposuctionSection
                    }
                    
                    // 備考
                    notesSection
                }
                .padding()
            }
            .navigationTitle("手術情報編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveChanges() }
                        .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadSurgeryData()
            }
        }
        .frame(minWidth: 800, minHeight: 600)
    }
    
    // MARK: - Sections
    
    private var basicInfoSection: some View {
        GroupBox(label: Label("基本情報（編集不可）", systemImage: "info.circle")) {
            VStack(alignment: .leading, spacing: 8) {
                InfoRowReadOnly(label: "手術日", value: formatDate(surgeryDate))
                InfoRowReadOnly(label: "カテゴリ", value: surgeryCategory)
                InfoRowReadOnly(label: "術式", value: surgeryType)
            }
            .padding(.vertical, 8)
        }
    }
    
    private var patientBasicInfoSection: some View {
        GroupBox(label: Label("患者基礎情報", systemImage: "person.fill")) {
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("身長 (cm)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("170.0", text: $height)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .onChange(of: height) { _, _ in calculateBMI() }
                            .onChange(of: bodyWeight) { _, _ in calculateBMI() }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("体重 (kg)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("60.0", text: $bodyWeight)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("BMI")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("自動計算", text: $bmi)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .disabled(true)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var breastAugmentationSection: some View {
        Group {
            // 患者情報（豊胸系）
            GroupBox(label: Label("患者情報（豊胸系）", systemImage: "heart.text.square")) {
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("喫煙歴")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("なし", text: $smokingHistory)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("授乳歴")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("なし", text: $breastfeedingHistory)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("手術回数")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0", text: $numberOfProcedures)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 術前測定値
            GroupBox(label: Label("術前測定値", systemImage: "ruler")) {
                VStack(spacing: 12) {
                    // Vectra測定
                    HStack {
                        Text("Vectra測定値 (cc)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("右")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0.0", text: $preOpVectraR)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        VStack(alignment: .leading) {
                            Text("左")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0.0", text: $preOpVectraL)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    // NAC-IMF距離
                    HStack {
                        Text("NAC-IMF距離 (cm)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("右")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0.0", text: $nacImfRight)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        VStack(alignment: .leading) {
                            Text("左")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0.0", text: $nacImfLeft)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    // 皮膚厚
                    HStack {
                        Text("皮膚厚 (mm)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Spacer()
                    }
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("右")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0.0", text: $skinThicknessRight)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        VStack(alignment: .leading) {
                            Text("左")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            TextField("0.0", text: $skinThicknessLeft)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                        }
                        Spacer()
                    }
                }
                .padding(.vertical, 8)
            }
        }
    }
    
    private var fatInjectionSection: some View {
        GroupBox(label: Label("脂肪注入詳細", systemImage: "drop.fill")) {
            VStack(spacing: 12) {
                // ドナー部位
                HStack {
                    Text("ドナー部位")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                Picker("ドナー部位", selection: $donorSite) {
                    Text("選択してください").tag("")
                    Text("腹部").tag("腹部")
                    Text("大腿部").tag("大腿部")
                    Text("腰部").tag("腰部")
                    Text("その他").tag("その他")
                }
                .pickerStyle(.segmented)
                
                if donorSite == "その他" {
                    TextField("その他のドナー部位を入力", text: $donorSiteOther)
                        .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                // 層別注入量
                VStack(spacing: 16) {
                    layeredVolumeRow(title: "皮下", rightBinding: $subcutaneousRight, leftBinding: $subcutaneousLeft)
                    layeredVolumeRow(title: "乳腺下", rightBinding: $subglandularRight, leftBinding: $subglandularLeft)
                    layeredVolumeRow(title: "筋肉下", rightBinding: $submuscularRight, leftBinding: $submuscularLeft)
                    layeredVolumeRow(title: "デコルテ", rightBinding: $decolletRight, leftBinding: $decolletLeft)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var siliconeSection: some View {
        GroupBox(label: Label("シリコン豊胸詳細", systemImage: "circle.circle")) {
            VStack(spacing: 12) {
                // インプラントサイズ
                HStack {
                    Text("インプラントサイズ (cc)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                HStack(spacing: 16) {
                    VStack(alignment: .leading) {
                        Text("右")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0", text: $implantSizeR)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    VStack(alignment: .leading) {
                        Text("左")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("0", text: $implantSizeL)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                    Spacer()
                }
                
                Divider()
                
                // メーカー
                VStack(alignment: .leading) {
                    Text("メーカー")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("メーカー名を入力", text: $implantManufacturer)
                        .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                // 切開部位
                VStack(alignment: .leading) {
                    Text("切開部位")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("切開部位", selection: $incisionSite) {
                        Text("選択してください").tag("")
                        Text("腋窩").tag("腋窩")
                        Text("乳輪").tag("乳輪")
                        Text("乳房下溝").tag("乳房下溝")
                    }
                    .pickerStyle(.segmented)
                }
                
                Divider()
                
                // 挿入層
                VStack(alignment: .leading) {
                    Text("挿入層")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Picker("挿入層", selection: $insertionPlane) {
                        Text("選択してください").tag("")
                        Text("乳腺下").tag("乳腺下")
                        Text("筋肉下").tag("筋肉下")
                        Text("デュアルプレーン").tag("デュアルプレーン")
                    }
                    .pickerStyle(.segmented)
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    // ✅ 修正: 脂肪吸引セクション（部位選択機能を追加）
    private var liposuctionSection: some View {
        GroupBox(label: Label("脂肪吸引詳細", systemImage: "tornado")) {
            VStack(spacing: 12) {
                // ✅ 追加: 吸引部位選択
                VStack(alignment: .leading, spacing: 12) {
                    Text("吸引部位")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    // AddSurgeryViewと同じ部位選択UI
                    VStack(alignment: .leading, spacing: 12) {
                        // 上肢
                        VStack(alignment: .leading, spacing: 8) {
                            Text("上肢")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            ForEach(["二の腕", "肩", "肩甲骨横"], id: \.self) { area in
                                Toggle(area, isOn: Binding(
                                    get: { selectedLiposuctionAreas.contains(area) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedLiposuctionAreas.insert(area)
                                        } else {
                                            selectedLiposuctionAreas.remove(area)
                                        }
                                    }
                                ))
                                .toggleStyle(.checkbox)
                            }
                        }
                        .padding(.leading, 8)
                        
                        // 体幹
                        VStack(alignment: .leading, spacing: 8) {
                            Text("体幹")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            ForEach(["腹", "ウエスト", "腰", "背中上", "背中下"], id: \.self) { area in
                                Toggle(area, isOn: Binding(
                                    get: { selectedLiposuctionAreas.contains(area) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedLiposuctionAreas.insert(area)
                                        } else {
                                            selectedLiposuctionAreas.remove(area)
                                        }
                                    }
                                ))
                                .toggleStyle(.checkbox)
                            }
                        }
                        .padding(.leading, 8)
                        
                        // 下肢
                        VStack(alignment: .leading, spacing: 8) {
                            Text("下肢")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            ForEach(["大腿", "臀部", "膝", "下腿", "足首"], id: \.self) { area in
                                Toggle(area, isOn: Binding(
                                    get: { selectedLiposuctionAreas.contains(area) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedLiposuctionAreas.insert(area)
                                        } else {
                                            selectedLiposuctionAreas.remove(area)
                                        }
                                    }
                                ))
                                .toggleStyle(.checkbox)
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
                
                Divider()
                
                // 術式（表示のみ）
                HStack {
                    Text("術式")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(surgeryType)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // 総吸引量
                VStack(alignment: .leading) {
                    Text("総吸引量 (cc)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    TextField("0", text: $liposuctionVolume)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)
                }
                
                Divider()
                
                // 使用機器
                HStack {
                    Text("使用機器")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                }
                HStack(spacing: 16) {
                    Toggle("Aquicell使用", isOn: $aquicellUsed)
                        .toggleStyle(.checkbox)
                    Toggle("Vaser使用", isOn: $vaserUsed)
                        .toggleStyle(.checkbox)
                    Spacer()
                }
            }
            .padding(.vertical, 8)
        }
    }
    
    private var notesSection: some View {
        GroupBox(label: Label("備考", systemImage: "note.text")) {
            TextEditor(text: $notes)
                .frame(minHeight: 120)
                .border(Color.secondary.opacity(0.3), width: 1)
                .padding(.vertical, 4)
        }
    }
    
    // MARK: - Helper Views
    
    private func layeredVolumeRow(title: String, rightBinding: Binding<String>, leftBinding: Binding<String>) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)
            
            VStack(alignment: .leading) {
                Text("右 (cc)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("0.0", text: rightBinding)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            
            VStack(alignment: .leading) {
                Text("左 (cc)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("0.0", text: leftBinding)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Data Management
    
    private func loadSurgeryData() {
        // 患者基礎情報
        height = surgery.height?.stringValue ?? ""
        bodyWeight = surgery.bodyWeight?.stringValue ?? ""
        bmi = surgery.bmi?.stringValue ?? ""
        
        // 患者情報（豊胸系）
        smokingHistory = surgery.smokingHistory ?? ""
        breastfeedingHistory = surgery.breastfeedingHistory ?? ""
        numberOfProcedures = surgery.numberOfProcedures?.stringValue ?? ""
        
        // 術前測定値
        preOpVectraR = surgery.preOpVectraR?.stringValue ?? ""
        preOpVectraL = surgery.preOpVectraL?.stringValue ?? ""
        nacImfRight = surgery.nacImfRight?.stringValue ?? ""
        nacImfLeft = surgery.nacImfLeft?.stringValue ?? ""
        skinThicknessRight = surgery.skinThicknessRight?.stringValue ?? ""
        skinThicknessLeft = surgery.skinThicknessLeft?.stringValue ?? ""
        
        // 脂肪注入
        donorSite = surgery.donorSite ?? ""
        donorSiteOther = surgery.donorSiteOther ?? ""
        subcutaneousRight = surgery.subcutaneousRight?.stringValue ?? ""
        subcutaneousLeft = surgery.subcutaneousLeft?.stringValue ?? ""
        subglandularRight = surgery.subglandularRight?.stringValue ?? ""
        subglandularLeft = surgery.subglandularLeft?.stringValue ?? ""
        submuscularRight = surgery.submuscularRight?.stringValue ?? ""
        submuscularLeft = surgery.submuscularLeft?.stringValue ?? ""
        decolletRight = surgery.decolletRight?.stringValue ?? ""
        decolletLeft = surgery.decolletLeft?.stringValue ?? ""
        
        // シリコン豊胸
        implantSizeR = surgery.implantSizeR?.stringValue ?? ""
        implantSizeL = surgery.implantSizeL?.stringValue ?? ""
        implantManufacturer = surgery.implantManufacturer ?? ""
        incisionSite = surgery.incisionSite ?? ""
        insertionPlane = surgery.insertionPlane ?? ""
        
        // ✅ 脂肪吸引部位の読み込みを追加
        if let donorSite = surgery.donorSite, surgeryCategory == "脂肪吸引" {
            selectedLiposuctionAreas = Set(donorSite.components(separatedBy: ", "))
        }
        
        liposuctionVolume = surgery.liposuctionVolume?.stringValue ?? ""
        aquicellUsed = surgery.aquicellUsed?.boolValue ?? false
        vaserUsed = surgery.vaserUsed?.boolValue ?? false
        
        // 備考
        notes = surgery.notes ?? ""
    }
    
    private func saveChanges() {
        // バリデーション
        if !validateInputs() {
            return
        }
        
        // 患者基礎情報
        surgery.height = parseDouble(height)
        surgery.bodyWeight = parseDouble(bodyWeight)
        surgery.bmi = parseDouble(bmi)
        
        // 患者情報（豊胸系）
        surgery.smokingHistory = smokingHistory.isEmpty ? nil : smokingHistory
        surgery.breastfeedingHistory = breastfeedingHistory.isEmpty ? nil : breastfeedingHistory
        surgery.numberOfProcedures = parseInt(numberOfProcedures)
        
        // 術前測定値
        surgery.preOpVectraR = parseDouble(preOpVectraR)
        surgery.preOpVectraL = parseDouble(preOpVectraL)
        surgery.nacImfRight = parseDouble(nacImfRight)
        surgery.nacImfLeft = parseDouble(nacImfLeft)
        surgery.skinThicknessRight = parseDouble(skinThicknessRight)
        surgery.skinThicknessLeft = parseDouble(skinThicknessLeft)
        
        // 脂肪注入
        if surgeryCategory == "豊胸系" && surgeryType.contains("脂肪注入") {
            surgery.donorSite = donorSite.isEmpty ? nil : donorSite
            surgery.donorSiteOther = donorSiteOther.isEmpty ? nil : donorSiteOther
        }
        
        surgery.subcutaneousRight = parseDouble(subcutaneousRight)
        surgery.subcutaneousLeft = parseDouble(subcutaneousLeft)
        surgery.subglandularRight = parseDouble(subglandularRight)
        surgery.subglandularLeft = parseDouble(subglandularLeft)
        surgery.submuscularRight = parseDouble(submuscularRight)
        surgery.submuscularLeft = parseDouble(submuscularLeft)
        surgery.decolletRight = parseDouble(decolletRight)
        surgery.decolletLeft = parseDouble(decolletLeft)
        
        // シリコン豊胸
        surgery.implantSizeR = parseInt(implantSizeR)
        surgery.implantSizeL = parseInt(implantSizeL)
        surgery.implantManufacturer = implantManufacturer.isEmpty ? nil : implantManufacturer
        surgery.incisionSite = incisionSite.isEmpty ? nil : incisionSite
        surgery.insertionPlane = insertionPlane.isEmpty ? nil : insertionPlane
        
        // ✅ 脂肪吸引部位の保存を修正
        if surgeryCategory == "脂肪吸引" {
            let selectedAreasString = selectedLiposuctionAreas.sorted().joined(separator: ", ")
            surgery.donorSite = selectedAreasString.isEmpty ? nil : selectedAreasString
        }
        
        surgery.liposuctionVolume = parseDouble(liposuctionVolume)
        surgery.aquicellUsed = NSNumber(value: aquicellUsed)
        surgery.vaserUsed = NSNumber(value: vaserUsed)
        
        // 備考
        surgery.notes = notes.isEmpty ? nil : notes
        
        // 保存
        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func validateInputs() -> Bool {
        // 数値入力のバリデーション
        let numericFields = [
            ("身長", height),
            ("体重", bodyWeight),
            ("術前Vectra右", preOpVectraR),
            ("術前Vectra左", preOpVectraL),
            ("皮下右", subcutaneousRight),
            ("皮下左", subcutaneousLeft),
            ("乳腺下右", subglandularRight),
            ("乳腺下左", subglandularLeft)
        ]
        
        for (name, value) in numericFields {
            if !value.isEmpty && Double(value) == nil {
                errorMessage = "\(name)には数値を入力してください"
                showError = true
                return false
            }
        }
        
        return true
    }
    
    private func calculateBMI() {
        guard let h = Double(height), let w = Double(bodyWeight), h > 0 else {
            bmi = ""
            return
        }
        let heightInMeters = h / 100.0
        let calculatedBMI = w / (heightInMeters * heightInMeters)
        bmi = String(format: "%.1f", calculatedBMI)
    }
    
    // MARK: - Helper Functions
    
    private func parseDouble(_ string: String) -> NSNumber? {
        guard !string.isEmpty, let value = Double(string) else { return nil }
        return NSNumber(value: value)
    }
    
    private func parseInt(_ string: String) -> NSNumber? {
        guard !string.isEmpty, let value = Int(string) else { return nil }
        return NSNumber(value: value)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Helper View: InfoRowReadOnly

private struct InfoRowReadOnly: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .frame(width: 100, alignment: .leading)
                .foregroundColor(.secondary)
            Text(value)
                .fontWeight(.medium)
            Spacer()
        }
    }
}

// MARK: - Preview


#Preview {
    NavigationView {
        SurgeryDetailView(
            surgery: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Surgery }) as! Surgery
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
