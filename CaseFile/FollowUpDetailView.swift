//
//  FollowUpDetailView.swift
//  CaseFile
//
//  経過情報詳細画面
//

import SwiftUI
import CoreData

struct FollowUpDetailView: View {
    @ObservedObject var followUp: FollowUp
    let surgery: Surgery
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var showEditView = false
    @State private var showDeleteAlert = false
    @State private var refreshID = UUID()
    @FocusState private var isFocused: Bool
    
    // MARK: - 定着率の計算
    private var retentionRateR: Double? {
        guard let postOpVectraR = followUp.postOpVectraR?.doubleValue,
              postOpVectraR > 0 else { return nil }
        
        let preOpVectraR = surgery.value(forKey: "preOpVectraR") as? Double ?? 0
        let injectionVolumeR = surgery.value(forKey: "injectionVolumeR") as? Double ?? 0
        
        guard injectionVolumeR > 0 else { return nil }
        
        return ((postOpVectraR - preOpVectraR) / injectionVolumeR) * 100
    }
    
    private var retentionRateL: Double? {
        guard let postOpVectraL = followUp.postOpVectraL?.doubleValue,
              postOpVectraL > 0 else { return nil }
        
        let preOpVectraL = surgery.value(forKey: "preOpVectraL") as? Double ?? 0
        let injectionVolumeL = surgery.value(forKey: "injectionVolumeL") as? Double ?? 0
        
        guard injectionVolumeL > 0 else { return nil }
        
        return ((postOpVectraL - preOpVectraL) / injectionVolumeL) * 100
    }
    
    // MARK: - 定着率の色分け
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
    
    // MARK: - リロード処理
    private func reloadFollowUpData() {
        viewContext.refresh(followUp, mergeChanges: true)
        viewContext.refresh(surgery, mergeChanges: true)
        refreshID = UUID()
        print("✅ 経過情報データをリロードしました")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // カスタムヘッダー(タイトル+ボタン)
            HStack {
                Text("経過情報詳細")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                // リロードボタン
                Button(action: {
                    reloadFollowUpData()
                }) {
                    Label("再読み込み", systemImage: "arrow.clockwise")
                }
                .help("キーボード: R で再読み込み")
                .buttonStyle(.plain)
                
                Button("編集") {
                    showEditView = true
                }
                .buttonStyle(.borderedProminent)
                
                Button("削除") {
                    showDeleteAlert = true
                }
                .buttonStyle(.bordered)
                .foregroundColor(.red)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // メインコンテンツ
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // 基本情報セクション
                    basicInfoSection
                    
                    // 測定値セクション(豊胸系のみ)
                    if surgery.surgeryCategory == "豊胸系" {
                        measurementsSection
                    }
                    
                    // 定着率セクション(豊胸系かつ脂肪注入のみ)
                    if shouldShowRetentionRate {
                        retentionRateSection
                    }
                    
                    // メモセクション
                    if let notes = followUp.notes, !notes.isEmpty {
                        notesSection(notes: notes)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .id(refreshID)
        .frame(minWidth: 700, idealWidth: 800, maxWidth: 1000,
               minHeight: 600, idealHeight: 700, maxHeight: 900)
        .focusable()
        .focused($isFocused)
        .onAppear {
            isFocused = true
        }
        .onKeyPress(characters: .alphanumerics) { press in
            if press.characters == "r" || press.characters == "R" {
                reloadFollowUpData()
                return .handled
            }
            return .ignored
        }
        .sheet(isPresented: $showEditView) {
            EditFollowUpView(followUp: followUp, surgery: surgery)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("削除確認", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteFollowUp()
            }
        } message: {
            Text("この経過情報を削除してもよろしいですか?")
        }
    }
    
    // MARK: - 基本情報セクション
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本情報")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // 記録日
            HStack {
                Text("記録日:")
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
                if let date = followUp.measurementDate {
                    Text(date, style: .date)
                } else {
                    Text("未設定")
                        .foregroundColor(.secondary)
                }
            }
            
            // タイミング
            HStack {
                Text("タイミング:")
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
                Text(followUp.timing ?? "未設定")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - 測定値セクション
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("測定値")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            // 右側測定値
            HStack {
                Text("Vectra R:")
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
                if let vectraR = followUp.postOpVectraR?.doubleValue, vectraR > 0 {
                    Text(String(format: "%.1f cc", vectraR))
                } else {
                    Text("未測定")
                        .foregroundColor(.secondary)
                }
            }
            
            // 左側測定値
            HStack {
                Text("Vectra L:")
                    .frame(width: 100, alignment: .leading)
                    .foregroundColor(.secondary)
                if let vectraL = followUp.postOpVectraL?.doubleValue, vectraL > 0 {
                    Text(String(format: "%.1f cc", vectraL))
                } else {
                    Text("未測定")
                        .foregroundColor(.secondary)
                }
            }
            
            // 体重
            if let weight = followUp.bodyWeight?.doubleValue, weight > 0 {
                HStack {
                    Text("体重:")
                        .frame(width: 100, alignment: .leading)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f kg", weight))
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - 定着率セクション
    private var retentionRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("定着率(自動計算)")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                // 右側定着率
                if let rateR = retentionRateR {
                    retentionRateRow(side: "右", rate: rateR)
                }
                
                if retentionRateR != nil && retentionRateL != nil {
                    Divider()
                }
                
                // 左側定着率
                if let rateL = retentionRateL {
                    retentionRateRow(side: "左", rate: rateL)
                }
            }
            .padding(.vertical, 8)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
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
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(retentionRateColor(rate).opacity(0.2))
                .cornerRadius(4)
        }
    }
    
    // MARK: - メモセクション
    private func notesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("メモ")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text(notes)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - 条件判定
    private var shouldShowRetentionRate: Bool {
        // 豊胸系かつ脂肪注入の場合のみ定着率を表示
        let isFatInjection = surgery.surgeryCategory == "豊胸系" && 
                            (surgery.surgeryType?.contains("脂肪注入") ?? false)
        
        return isFatInjection && (retentionRateR != nil || retentionRateL != nil)
    }
    
    // MARK: - 削除処理
    private func deleteFollowUp() {
        viewContext.delete(followUp)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("削除エラー: \(error)")
        }
    }
}

struct FollowUpDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let surgery = Surgery(context: context)
        surgery.surgeryCategory = "豊胸系"
        surgery.surgeryType = "脂肪注入"
        surgery.setValue(250.0, forKey: "injectionVolumeR")
        surgery.setValue(250.0, forKey: "injectionVolumeL")
        surgery.setValue(200.0, forKey: "preOpVectraR")
        surgery.setValue(200.0, forKey: "preOpVectraL")
        
        let followUp = FollowUp(context: context)
        followUp.id = UUID()
        followUp.measurementDate = Date()
        followUp.timing = "1ヶ月後"
        followUp.notes = "順調に回復しています"
        followUp.postOpVectraR = NSNumber(value: 350.0)
        followUp.postOpVectraL = NSNumber(value: 345.0)
        followUp.bodyWeight = NSNumber(value: 52.5)
        followUp.surgery = surgery
        
        return FollowUpDetailView(followUp: followUp, surgery: surgery)
            .environment(\.managedObjectContext, context)
            .frame(width: 800, height: 700)
    }
}
