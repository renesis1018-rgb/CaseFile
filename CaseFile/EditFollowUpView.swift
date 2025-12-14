//
//  EditFollowUpView.swift
//  CaseFile
//
//  経過情報編集画面 - Phase 4新規作成
//  機能: 測定日、Vectra測定値、体重、備考の編集、バリデーション、術後日数自動計算
//

import SwiftUI
import CoreData

struct EditFollowUpView: View {
    @ObservedObject var followUp: FollowUp
    var surgery: Surgery
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 編集用State
    @State private var followUpDate: Date
    @State private var vectraValueRight: String
    @State private var vectraValueLeft: String
    @State private var bodyWeight: String
    @State private var notes: String
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    init(followUp: FollowUp, surgery: Surgery) {
        self.followUp = followUp
        self.surgery = surgery
        
        // 既存値で初期化
        _followUpDate = State(initialValue: followUp.followUpDate ?? Date())
        _vectraValueRight = State(initialValue: followUp.postOpVectraR != nil && followUp.postOpVectraR!.doubleValue > 0 ? 
            String(format: "%.0f", followUp.postOpVectraR!.doubleValue) : "")
        _vectraValueLeft = State(initialValue: followUp.postOpVectraL != nil && followUp.postOpVectraL!.doubleValue > 0 ? 
            String(format: "%.0f", followUp.postOpVectraL!.doubleValue) : "")
        _bodyWeight = State(initialValue: followUp.bodyWeightKg != nil && followUp.bodyWeightKg!.doubleValue > 0 ? 
            String(format: "%.1f", followUp.bodyWeightKg!.doubleValue) : "")
        _notes = State(initialValue: followUp.notes ?? "")
    }
    
    var body: some View {
        NavigationView {
            Form {
                // 基本情報セクション
                Section("基本情報") {
                    DatePicker("測定日", selection: $followUpDate, displayedComponents: .date)
                        .datePickerStyle(.graphical)
                    
                    // 術後日数（表示のみ）
                    HStack {
                        Text("術後日数")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(calculatedDayAfterSurgery)
                            .foregroundColor(.primary)
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
                
                // 測定値セクション（豊胸系のみ）
                if shouldShowMeasurements {
                    Section("測定値（豊胸系）") {
                        // Vectra測定値
                        HStack {
                            Text("Vectra測定値（右）")
                            Spacer()
                            TextField("cc", text: $vectraValueRight)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        HStack {
                            Text("Vectra測定値（左）")
                            Spacer()
                            TextField("cc", text: $vectraValueLeft)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 100)
                                .multilineTextAlignment(.trailing)
                        }
                        
                        // 定着率（表示のみ）
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("定着率")
                                    .foregroundColor(.secondary)
                                Image(systemName: "bolt.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                                Text("自動計算")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("右: \(calculatedRetentionRateRight)")
                                Spacer()
                                Text("左: \(calculatedRetentionRateLeft)")
                            }
                            .foregroundColor(.primary)
                            .padding(.vertical, 4)
                        }
                    }
                }
                
                // 患者状態セクション
                Section("患者状態") {
                    HStack {
                        Text("体重")
                        Spacer()
                        TextField("kg", text: $bodyWeight)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // 備考セクション
                Section("備考") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("経過情報編集")
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
            .alert("入力エラー", isPresented: $showAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
        .frame(minWidth: 600, minHeight: 700)
    }
    
    // MARK: - Computed Properties
    
    private var shouldShowMeasurements: Bool {
        guard let category = surgery.surgeryCategory else { return false }
        return category == "豊胸系"
    }
    
    private var calculatedDayAfterSurgery: String {
        guard let surgeryDate = surgery.surgeryDate else {
            return "計算不可"
        }
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: surgeryDate, to: followUpDate)
        if let days = components.day {
            return "\(days)日"
        }
        return "計算不可"
    }
    
    // 定着率計算（右）
    private var calculatedRetentionRateRight: String {
        guard shouldShowMeasurements,
              let vectraRight = Double(vectraValueRight), vectraRight > 0,
              let injectionRight = surgery.injectionVolumeR, injectionRight.doubleValue > 0 else {
            return "未計算"
        }
        
        let rate = (vectraRight / injectionRight.doubleValue) * 100
        return String(format: "%.1f%%", rate)
    }
    
    // 定着率計算（左）
    private var calculatedRetentionRateLeft: String {
        guard shouldShowMeasurements,
              let vectraLeft = Double(vectraValueLeft), vectraLeft > 0,
              let injectionLeft = surgery.injectionVolumeL, injectionLeft.doubleValue > 0 else {
            return "未計算"
        }
        
        let rate = (vectraLeft / injectionLeft.doubleValue) * 100
        return String(format: "%.1f%%", rate)
    }
    
    // MARK: - Actions
    
    private func saveFollowUp() {
        // バリデーション1: 測定日が未来日でないか
        guard followUpDate <= Date() else {
            alertMessage = "測定日は未来日にできません。"
            showAlert = true
            return
        }
        
        // バリデーション2: Vectra測定値（豊胸系の場合）
        if shouldShowMeasurements {
            if !vectraValueRight.isEmpty {
                guard let value = Double(vectraValueRight), value > 0 else {
                    alertMessage = "Vectra測定値（右）は正の数値を入力してください。"
                    showAlert = true
                    return
                }
            }
            
            if !vectraValueLeft.isEmpty {
                guard let value = Double(vectraValueLeft), value > 0 else {
                    alertMessage = "Vectra測定値（左）は正の数値を入力してください。"
                    showAlert = true
                    return
                }
            }
        }
        
        // バリデーション3: 体重
        if !bodyWeight.isEmpty {
            guard let value = Double(bodyWeight), value > 0 else {
                alertMessage = "体重は正の数値を入力してください。"
                showAlert = true
                return
            }
        }
        
        // 術後日数の計算

        
        // データ保存
        followUp.followUpDate = followUpDate
        followUp.postOpVectraR = vectraValueRight.isEmpty ? nil : NSNumber(value: Double(vectraValueRight) ?? 0)
        followUp.postOpVectraL = vectraValueLeft.isEmpty ? nil : NSNumber(value: Double(vectraValueLeft) ?? 0)
        followUp.bodyWeightKg = bodyWeight.isEmpty ? nil : NSNumber(value: Double(bodyWeight) ?? 0)
        followUp.notes = notes.isEmpty ? nil : notes
        
        // 定着率の計算（保存時には自動計算しない。表示時に計算）
        // retentionRateRight/Leftは使用しない想定（コメントアウトまたは削除）
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "保存に失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Preview

#Preview {
    EditFollowUpView(
        followUp: {
            let context = PersistenceController.preview.container.viewContext
            let followUp = FollowUp(context: context)
            followUp.followUpDate = Date()
            followUp.postOpVectraR = NSNumber(value: 250)
            followUp.postOpVectraL = NSNumber(value: 240)
            followUp.bodyWeightKg = NSNumber(value: 52.5)
            followUp.notes = "順調な経過"
            return followUp
        }(),
        surgery: {
            let context = PersistenceController.preview.container.viewContext
            let surgery = Surgery(context: context)
            surgery.surgeryCategory = "豊胸系"
            surgery.surgeryType = "脂肪注入"
            surgery.surgeryDate = Calendar.current.date(byAdding: .month, value: -1, to: Date())
            surgery.injectionVolumeR = NSNumber(value: 300)
            surgery.injectionVolumeL = NSNumber(value: 290)
            return surgery
        }()
    )
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
