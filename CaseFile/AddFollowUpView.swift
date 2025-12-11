//
//  AddFollowUpView.swift
//  CaseFile
//
//  経過情報（フォローアップ）入力画面
//

import SwiftUI
import CoreData

struct AddFollowUpView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var surgery: Surgery
    let context: NSManagedObjectContext
    
    // MARK: - 基本情報
    @State private var followUpDate = Date()
    @State private var dayAfterSurgery = ""
    
    // MARK: - 測定値
    @State private var vectraValueRight = ""
    @State private var vectraValueLeft = ""
    @State private var bodyWeight = ""
    
    // MARK: - 備考
    @State private var notes = ""
    
    // MARK: - 自動計算（定着率）
    @State private var retentionRateRight: Double? = nil
    @State private var retentionRateLeft: Double? = nil
    
    // MARK: - エラー表示
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - 基本情報
                    basicInfoSection
                    
                    // MARK: - 測定値
                    measurementsSection
                    
                    // MARK: - 定着率（自動計算・表示のみ）
                    retentionRateSection
                    
                    // MARK: - 備考
                    notesSection
                }
            }
            .navigationTitle("経過情報登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveFollowUp() }
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(minWidth: 800, idealWidth: 900, minHeight: 700)
        .onAppear {
            calculateDaysAfterSurgery()
        }
    }
    
    // MARK: - 基本情報セクション
    private var basicInfoSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("基本情報")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                DatePicker("フォローアップ日", selection: $followUpDate, displayedComponents: .date)
                    .onChange(of: followUpDate) {
                        calculateDaysAfterSurgery()
                    }
                
                HStack {
                    Text("術後経過日数")
                        .frame(width: 120, alignment: .leading)
                    TextField("自動計算", text: $dayAfterSurgery)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                        .disabled(true)
                    Text("日")
                }
                
                Divider()
                    .padding(.vertical, 8)
                
                if let surgeryDate = surgery.surgeryDate {
                    HStack {
                        Text("手術日")
                            .frame(width: 120, alignment: .leading)
                            .foregroundColor(.secondary)
                        Text(formatDate(surgeryDate))
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Text("手術種別")
                        .frame(width: 120, alignment: .leading)
                        .foregroundColor(.secondary)
                    Text(surgery.surgeryType ?? "不明")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .padding()
    }
    
    // MARK: - 測定値セクション
    private var measurementsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("測定値")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    MeasurementField(label: "Vectra測定値 (R)", value: $vectraValueRight, unit: "cc")
                        .onChange(of: vectraValueRight) {
                            calculateRetentionRate()
                        }
                    MeasurementField(label: "Vectra測定値 (L)", value: $vectraValueLeft, unit: "cc")
                        .onChange(of: vectraValueLeft) {
                            calculateRetentionRate()
                        }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("体重")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 4) {
                            TextField("", text: $bodyWeight)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                            
                            Text("kg")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 40, alignment: .leading)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 定着率セクション（自動計算・表示のみ）
    private var retentionRateSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("定着率（自動計算）")
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                        .help("定着率 = (フォローアップVectra - 術前Vectra) / 注入量 × 100")
                }
                .padding(.bottom, 4)
                
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("右側")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let rate = retentionRateRight {
                            HStack(spacing: 8) {
                                Text(String(format: "%.1f", rate))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(retentionRateColor(rate))
                                Text("%")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("計算できません")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let rate = retentionRateRight {
                            Text(retentionRateComment(rate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("左側")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let rate = retentionRateLeft {
                            HStack(spacing: 8) {
                                Text(String(format: "%.1f", rate))
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(retentionRateColor(rate))
                                Text("%")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("計算できません")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        if let rate = retentionRateLeft {
                            Text(retentionRateComment(rate))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                .cornerRadius(8)
                
                // 計算に必要なデータの表示
                VStack(alignment: .leading, spacing: 4) {
                    Text("計算に使用したデータ:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        if let preOpR = surgery.preOpVectraR?.doubleValue {
                            Text("術前Vectra(R): \(String(format: "%.0f", preOpR))cc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let injR = surgery.injectionVolumeR?.doubleValue {
                            Text("注入量(R): \(String(format: "%.0f", injR))cc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        if let preOpL = surgery.preOpVectraL?.doubleValue {
                            Text("術前Vectra(L): \(String(format: "%.0f", preOpL))cc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        if let injL = surgery.injectionVolumeL?.doubleValue {
                            Text("注入量(L): \(String(format: "%.0f", injL))cc")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 備考セクション
    private var notesSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("備考")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                TextEditor(text: $notes)
                    .frame(height: 150)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - Helper
    
    private func calculateDaysAfterSurgery() {
        guard let surgeryDate = surgery.surgeryDate else {
            dayAfterSurgery = "0"
            return
        }
        
        let days = Calendar.current.dateComponents([.day], from: surgeryDate, to: followUpDate).day ?? 0
        dayAfterSurgery = "\(max(0, days))"
    }
    
    private func calculateRetentionRate() {
        // 右側の定着率計算
        if let vectraR = Double(vectraValueRight),
           let preOpVectraR = surgery.preOpVectraR?.doubleValue,
           let injectionR = surgery.injectionVolumeR?.doubleValue,
           injectionR > 0 {
            let volumeIncrease = vectraR - preOpVectraR
            retentionRateRight = (volumeIncrease / injectionR) * 100
        } else {
            retentionRateRight = nil
        }
        
        // 左側の定着率計算
        if let vectraL = Double(vectraValueLeft),
           let preOpVectraL = surgery.preOpVectraL?.doubleValue,
           let injectionL = surgery.injectionVolumeL?.doubleValue,
           injectionL > 0 {
            let volumeIncrease = vectraL - preOpVectraL
            retentionRateLeft = (volumeIncrease / injectionL) * 100
        } else {
            retentionRateLeft = nil
        }
    }
    
    private func retentionRateColor(_ rate: Double) -> Color {
        switch rate {
        case 70...: return .green
        case 50..<70: return .orange
        default: return .red
        }
    }
    
    private func retentionRateComment(_ rate: Double) -> String {
        switch rate {
        case 70...: return "良好な定着"
        case 50..<70: return "標準的な定着"
        default: return "低い定着"
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    
    // MARK: - 保存処理
    private func saveFollowUp() {
        let newFollowUp = FollowUp(context: context)
        newFollowUp.id = UUID()
        newFollowUp.surgery = surgery
        newFollowUp.followUpDate = followUpDate
        
        // すべてのデータを notes に統合して保存
        let daysNote = "【術後経過】\(dayAfterSurgery)日\n"
        let weightNote = bodyWeight.isEmpty ? "" : "【体重】\(bodyWeight)kg\n"
        
        let vectraNote = """
        【Vectra測定値】
        右: \(vectraValueRight.isEmpty ? "未測定" : vectraValueRight + "cc")
        左: \(vectraValueLeft.isEmpty ? "未測定" : vectraValueLeft + "cc")
        
        """
        
        var retentionNote = ""
        if let rateR = retentionRateRight {
            retentionNote += "【定着率(R)】\(String(format: "%.1f", rateR))%\n"
        }
        if let rateL = retentionRateLeft {
            retentionNote += "【定着率(L)】\(String(format: "%.1f", rateL))%\n"
        }
        if !retentionNote.isEmpty {
            retentionNote += "\n"
        }
        
        // すべてのメモを統合
        newFollowUp.notes = daysNote + weightNote + vectraNote + retentionNote + notes
        
        // Core Data保存
        do {
            try context.save()
            print("✅ 経過情報保存成功")
            print("  術後経過日数: \(dayAfterSurgery)日")
            print("  定着率(R): \(retentionRateRight.map { String(format: "%.1f%%", $0) } ?? "計算不可")")
            print("  定着率(L): \(retentionRateLeft.map { String(format: "%.1f%%", $0) } ?? "計算不可")")
            dismiss()
        } catch let error as NSError {
            print("❌ 経過情報保存エラー: \(error)")
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - 測定値入力フィールド（再利用可能コンポーネント）
struct MeasurementField: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                TextField("", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(width: 40, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let surgery = Surgery(context: context)
    surgery.id = UUID()
    surgery.surgeryType = "脂肪注入"
    surgery.surgeryDate = Date().addingTimeInterval(-30 * 24 * 60 * 60) // 30日前
    surgery.preOpVectraR = NSNumber(value: 200)
    surgery.preOpVectraL = NSNumber(value: 200)
    surgery.injectionVolumeR = NSNumber(value: 150)
    surgery.injectionVolumeL = NSNumber(value: 150)
    
    return AddFollowUpView(surgery: surgery, context: context)
}

