//
//  AddFollowUpView.swift
//  CaseFile
//
//  経過情報登録画面
//

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
                
                // 測定値セクション(手術カテゴリーに応じて表示)
                if shouldShowMeasurements {
                    measurementsSection
                }
                
                // 備考セクション
                notesSection
                
                // 定着率セクション(豊胸系かつ脂肪注入のみ)
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
            // 豊胸系(脂肪注入・シリコン)のみVectra値を表示
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
            
            // 豊胸系(脂肪注入・シリコン)・脂肪吸引は体重を表示
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
    
    // MARK: - 定着率セクション(豊胸系かつ脂肪注入のみ)
    private var retentionRateSection: some View {
        Section(header: Text("定着率(自動計算)")) {
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
        
        // ✅ 修正: 術前Vectra値を正しく取得
        let preOpVectraR = surgery.value(forKey: "preOpVectraR") as? Double ?? 0
        let preOpVectraL = surgery.value(forKey: "preOpVectraL") as? Double ?? 0
        
        // ✅ 修正: 注入量を正しく取得
        let injectionVolumeR = surgery.value(forKey: "injectionVolumeR") as? Double ?? 0
        let injectionVolumeL = surgery.value(forKey: "injectionVolumeL") as? Double ?? 0
        
        // 右側定着率
        if preOpVectraR > 0 && injectionVolumeR > 0 && vectraRight > 0 {
            retentionRateRight = ((vectraRight - preOpVectraR) / injectionVolumeR) * 100
        } else {
            retentionRateRight = 0
        }
        
        // 左側定着率
        if preOpVectraL > 0 && injectionVolumeL > 0 && vectraLeft > 0 {
            retentionRateLeft = ((vectraLeft - preOpVectraL) / injectionVolumeL) * 100
        } else {
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
        // バリデーション: 未来の日付チェック
        if measurementDate > Date() {
            alertTitle = "入力エラー"
            alertMessage = "記録日は未来の日付を設定できません"
            showAlert = true
            return
        }
        
        // Vectra値のバリデーション
        if !vectraValueRight.isEmpty {
            guard let vectraR = Double(vectraValueRight), vectraR >= 0 else {
                alertTitle = "入力エラー"
                alertMessage = "Vectra 右の値が不正です"
                showAlert = true
                return
            }
        }
        
        if !vectraValueLeft.isEmpty {
            guard let vectraL = Double(vectraValueLeft), vectraL >= 0 else {
                alertTitle = "入力エラー"
                alertMessage = "Vectra 左の値が不正です"
                showAlert = true
                return
            }
        }
        
        // 体重のバリデーション
        if !bodyWeight.isEmpty {
            guard let weight = Double(bodyWeight), weight > 0 else {
                alertTitle = "入力エラー"
                alertMessage = "体重の値が不正です"
                showAlert = true
                return
            }
        }
        
        // ✅ 修正: Core Dataエンティティを作成
        let newFollowUp = FollowUp(context: context)
        newFollowUp.id = UUID()
        newFollowUp.measurementDate = measurementDate
        newFollowUp.surgery = surgery
        
        // ✅ 修正: Core Dataの専用フィールドに直接保存
        newFollowUp.postOpVectraR = vectraValueRight.isEmpty ? nil : NSNumber(value: Double(vectraValueRight)!)
        newFollowUp.postOpVectraL = vectraValueLeft.isEmpty ? nil : NSNumber(value: Double(vectraValueLeft)!)
        newFollowUp.bodyWeight = bodyWeight.isEmpty ? nil : NSNumber(value: Double(bodyWeight)!)
        
        // ✅ 修正: タイミングを自動設定
        if let surgeryDate = surgery.surgeryDate {
            let days = Calendar.current.dateComponents([.day], from: surgeryDate, to: measurementDate).day ?? 0
            newFollowUp.timing = "\(days)日後"
        }
        
        // ✅ 修正: notesはユーザー入力のメモのみ保存
        newFollowUp.notes = notes.isEmpty ? nil : notes
        
        // Core Dataに保存
        do {
            try context.save()
            print("✅ 経過情報を保存しました")
            print("   - measurementDate: \(measurementDate)")
            print("   - postOpVectraR: \(newFollowUp.postOpVectraR?.doubleValue ?? 0)")
            print("   - postOpVectraL: \(newFollowUp.postOpVectraL?.doubleValue ?? 0)")
            print("   - bodyWeight: \(newFollowUp.bodyWeight?.doubleValue ?? 0)")
            print("   - timing: \(newFollowUp.timing ?? "nil")")
            
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
        
        // 豊胸系(脂肪注入)の手術
        let fatInjectionSurgery = Surgery(context: context)
        fatInjectionSurgery.id = UUID()
        fatInjectionSurgery.surgeryDate = Date()
        fatInjectionSurgery.surgeryCategory = "豊胸系"
        fatInjectionSurgery.surgeryType = "脂肪注入"
        fatInjectionSurgery.setValue(250.0, forKey: "injectionVolumeR")
        fatInjectionSurgery.setValue(250.0, forKey: "injectionVolumeL")
        fatInjectionSurgery.setValue(200.0, forKey: "preOpVectraR")
        fatInjectionSurgery.setValue(200.0, forKey: "preOpVectraL")
        
        // 豊胸系(シリコン)の手術
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
