import SwiftUI
import CoreData

struct AddFollowUpView: View {
    @Environment(\.managedObjectContext) private var context
    @Environment(\.dismiss) private var dismiss
    
    let surgery: Surgery
    
    @State private var measurementDate = Date()
    @State private var vectraValueRight: String = ""
    @State private var vectraValueLeft: String = ""
    @State private var bodyWeight: String = ""
    @State private var notes: String = ""
    
    // 自動計算
    @State private var dayAfterSurgery: Int = 0
    @State private var retentionRateRight: Double = 0
    @State private var retentionRateLeft: Double = 0
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // 基本情報セクション
                basicInfoSection
                
                // 測定値セクション（手術カテゴリーに応じて表示）
                if shouldShowMeasurements {
                    measurementsSection
                }
                
                // 備考セクション
                notesSection
                
                // 定着率セクション（豊胸系かつ脂肪注入のみ）
                if shouldShowRetentionRate {
                    retentionRateSection
                }
            }
            .navigationTitle("経過情報登録")
            .frame(minWidth: 500, minHeight: 400)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveFollowUp()
                    }
                }
            }
            .onChange(of: measurementDate) {
                calculateDayAfterSurgery()
            }
            .onChange(of: vectraValueRight) {
                calculateRetentionRate()
            }
            .onChange(of: vectraValueLeft) {
                calculateRetentionRate()
            }
            .onAppear {
                calculateDayAfterSurgery()
            }
            .alert(alertTitle, isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
        .frame(minWidth: 550, minHeight: 450)
    }
    
    // MARK: - 基本情報セクション
    private var basicInfoSection: some View {
        Section(header: Text("基本情報")) {
            DatePicker("経過観察日", selection: $measurementDate, displayedComponents: .date)
            
            HStack {
                Text("術後日数")
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(dayAfterSurgery)日")
                    .foregroundColor(.blue)
                    .bold()
            }
        }
    }
    
    // MARK: - 測定値セクション
    private var measurementsSection: some View {
        Section(header: Text("測定値")) {
            // 豊胸系（脂肪注入・シリコン）のみVectra値を表示
            if isBreastSurgery {
                HStack {
                    Text("Vectra 右 (cc)")
                        .frame(width: 140, alignment: .leading)
                    TextField("例: 250", text: $vectraValueRight)
                        .frame(maxWidth: 150)
                }
                
                HStack {
                    Text("Vectra 左 (cc)")
                        .frame(width: 140, alignment: .leading)
                    TextField("例: 250", text: $vectraValueLeft)
                        .frame(maxWidth: 150)
                }
            }
            
            // 豊胸系（脂肪注入・シリコン）・脂肪吸引は体重を表示
            if isBreastSurgery || isLiposuction {
                HStack {
                    Text("体重 (kg)")
                        .frame(width: 140, alignment: .leading)
                    TextField("例: 55.5", text: $bodyWeight)
                        .frame(maxWidth: 150)
                }
            }
        }
    }
    
    // MARK: - 備考セクション
    private var notesSection: some View {
        Section(header: Text("備考")) {
            TextEditor(text: $notes)
                .frame(minHeight: 120)
                .border(Color.gray.opacity(0.2), width: 1)
        }
    }
    
    // MARK: - 定着率セクション（豊胸系かつ脂肪注入のみ）
    private var retentionRateSection: some View {
        Section(header: Text("定着率（自動計算）")) {
            VStack(alignment: .leading, spacing: 12) {
                retentionRateRow(side: "右", rate: retentionRateRight)
                Divider()
                retentionRateRow(side: "左", rate: retentionRateLeft)
            }
            .padding(.vertical, 8)
        }
    }
    
    // MARK: - 定着率表示行
    private func retentionRateRow(side: String, rate: Double) -> some View {
        HStack {
            Text(side)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 40, alignment: .leading)
            
            Text(String(format: "%.1f%%", rate))
                .font(.title3)
                .bold()
                .foregroundColor(retentionRateColor(rate))
            
            Spacer()
            
            Text(retentionRateComment(rate))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - 条件判定
    private var isBreastSurgery: Bool {
        surgery.surgeryCategory == "豊胸系"
    }
    
    private var isFatInjection: Bool {
        surgery.surgeryCategory == "豊胸系" && surgery.surgeryType == "脂肪注入"
    }
    
    private var isLiposuction: Bool {
        surgery.surgeryCategory == "脂肪吸引"
    }
    
    private var isEyeSurgery: Bool {
        surgery.surgeryCategory == "目元系"
    }
    
    private var shouldShowMeasurements: Bool {
        isBreastSurgery || isLiposuction
    }
    
    private var shouldShowRetentionRate: Bool {
        // 豊胸系かつ脂肪注入の場合のみ定着率を表示
        isFatInjection && (Double(vectraValueRight) ?? 0 > 0 || Double(vectraValueLeft) ?? 0 > 0)
    }
    
    // MARK: - 計算処理
    private func calculateDayAfterSurgery() {
        guard let surgeryDate = surgery.surgeryDate else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: surgeryDate, to: measurementDate)
        dayAfterSurgery = components.day ?? 0
    }
    
    private func calculateRetentionRate() {
        guard isFatInjection else { return }
        
        let vectraRight = Double(vectraValueRight) ?? 0
        let vectraLeft = Double(vectraValueLeft) ?? 0
        
        // 術前Vectra値を取得
        let preOpVectra = surgery.preOpVectra?.doubleValue ?? 0
        
        // 注入量を取得（Core Dataに存在しない場合は計算不可）
        let injectionVolume: Double = 0 // 仮の値（実際の属性がないため）
        
        if preOpVectra > 0 && injectionVolume > 0 {
            retentionRateRight = ((vectraRight - preOpVectra) / injectionVolume) * 100
            retentionRateLeft = ((vectraLeft - preOpVectra) / injectionVolume) * 100
        } else {
            retentionRateRight = 0
            retentionRateLeft = 0
        }
    }
    
    private func retentionRateColor(_ rate: Double) -> Color {
        if rate >= 70 { return .green }
        if rate >= 50 { return .orange }
        return .red
    }
    
    private func retentionRateComment(_ rate: Double) -> String {
        if rate >= 70 { return "良好" }
        if rate >= 50 { return "標準" }
        return "要観察"
    }
    
    // MARK: - 保存処理
    private func saveFollowUp() {
        let newFollowUp = FollowUp(context: context)
        newFollowUp.id = UUID()
        newFollowUp.measurementDate = measurementDate  // ✅ 修正: followUpDate → measurementDate
        newFollowUp.surgery = surgery
        
        // ✅ 追加: Core Data属性に直接保存
        newFollowUp.postOpVectraR = vectraValueRight.isEmpty ? nil : NSNumber(value: Double(vectraValueRight)!)
        newFollowUp.postOpVectraL = vectraValueLeft.isEmpty ? nil : NSNumber(value: Double(vectraValueLeft)!)
        newFollowUp.bodyWeight = bodyWeight.isEmpty ? nil : NSNumber(value: Double(bodyWeight)!)
        
        // ✅ 追加: タイミングを自動設定
        newFollowUp.timing = "\(dayAfterSurgery)日後"
        
        // 備考欄にすべての情報を保存
        var notesText = ""
        
        // 術後日数
        notesText += "術後日数: \(dayAfterSurgery)日\n"
        
        // 豊胸系の場合
        if isBreastSurgery {
            if let vectraRight = Double(vectraValueRight), vectraRight > 0 {
                notesText += "Vectra 右: \(Int(vectraRight)) cc\n"
            }
            if let vectraLeft = Double(vectraValueLeft), vectraLeft > 0 {
                notesText += "Vectra 左: \(Int(vectraLeft)) cc\n"
            }
            
            // 定着率は脂肪注入のみ
            if isFatInjection {
                if retentionRateRight > 0 {
                    notesText += "定着率 右: \(String(format: "%.1f%%", retentionRateRight))\n"
                }
                if retentionRateLeft > 0 {
                    notesText += "定着率 左: \(String(format: "%.1f%%", retentionRateLeft))\n"
                }
            }
        }
        
        // 体重（豊胸系・脂肪吸引）
        if (isBreastSurgery || isLiposuction), let weight = Double(bodyWeight), weight > 0 {
            notesText += "体重: \(String(format: "%.1f kg", weight))\n"
        }
        
        // ユーザー備考
        if !notes.isEmpty {
            notesText += "\n【備考】\n\(notes)"
        }
        
        newFollowUp.notes = notesText
        
        do {
            try context.save()
            print("✅ 経過情報を保存しました")
            
            alertTitle = "保存完了"
            alertMessage = "経過情報を保存しました。"
            showAlert = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        } catch {
            print("❌ 経過情報の保存に失敗: \(error.localizedDescription)")
            alertTitle = "保存失敗"
            alertMessage = "経過情報の保存に失敗しました。\n\nエラー: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - プレビュー
struct AddFollowUpView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        // 豊胸系（脂肪注入）の手術
        let fatInjectionSurgery = Surgery(context: context)
        fatInjectionSurgery.id = UUID()
        fatInjectionSurgery.surgeryDate = Date()
        fatInjectionSurgery.surgeryCategory = "豊胸系"
        fatInjectionSurgery.surgeryType = "脂肪注入"
        
        // 豊胸系（シリコン）の手術
        let siliconeSurgery = Surgery(context: context)
        siliconeSurgery.id = UUID()
        siliconeSurgery.surgeryDate = Date()
        siliconeSurgery.surgeryCategory = "豊胸系"
        siliconeSurgery.surgeryType = "シリコン"
        
        // 脂肪吸引の手術
        let lipoSurgery = Surgery(context: context)
        lipoSurgery.id = UUID()
        lipoSurgery.surgeryDate = Date()
        lipoSurgery.surgeryCategory = "脂肪吸引"
        lipoSurgery.surgeryType = "腹部"
        
        // 目元系の手術
        let eyeSurgery = Surgery(context: context)
        eyeSurgery.id = UUID()
        eyeSurgery.surgeryDate = Date()
        eyeSurgery.surgeryCategory = "目元系"
        eyeSurgery.surgeryType = "二重埋没法"
        
        return Group {
            AddFollowUpView(surgery: fatInjectionSurgery)
                .environment(\.managedObjectContext, context)
                .previewDisplayName("脂肪注入")
            
            AddFollowUpView(surgery: siliconeSurgery)
                .environment(\.managedObjectContext, context)
                .previewDisplayName("シリコン豊胸")
            
            AddFollowUpView(surgery: lipoSurgery)
                .environment(\.managedObjectContext, context)
                .previewDisplayName("脂肪吸引")
            
            AddFollowUpView(surgery: eyeSurgery)
                .environment(\.managedObjectContext, context)
                .previewDisplayName("目元系")
        }
    }
}
