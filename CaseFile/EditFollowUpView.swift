//
//  EditFollowUpView.swift
//  CaseFile
//
//  経過情報編集画面
//

import SwiftUI
import CoreData

struct EditFollowUpView: View {
    @ObservedObject var followUp: FollowUp
    let surgery: Surgery
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    // 編集用の状態変数
    @State private var measurementDate: Date
    @State private var postOpVectraR: String
    @State private var postOpVectraL: String
    @State private var bodyWeight: String
    @State private var notes: String
    
    // バリデーションとアラート
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // ✅ 追加: リフレッシュ用
    @State private var refreshID = UUID()
    
    // 計算プロパティ
    private var dayAfterSurgery: Int {
        guard let surgeryDate = surgery.surgeryDate else { return 0 }
        return Calendar.current.dateComponents([.day], from: surgeryDate, to: measurementDate).day ?? 0
    }
    
    private var retentionRateR: Double? {
        guard let vectraR = Double(postOpVectraR) else { return nil }
        
        let preOpR = surgery.value(forKey: "preOpVectraR") as? Double ?? 0
        let injectionR = surgery.value(forKey: "injectionVolumeR") as? Double ?? 0
        
        guard injectionR > 0 else { return nil }
        
        return ((vectraR - preOpR) / injectionR) * 100
    }
    
    private var retentionRateL: Double? {
        guard let vectraL = Double(postOpVectraL) else { return nil }
        
        let preOpL = surgery.value(forKey: "preOpVectraL") as? Double ?? 0
        let injectionL = surgery.value(forKey: "injectionVolumeL") as? Double ?? 0
        
        guard injectionL > 0 else { return nil }
        
        return ((vectraL - preOpL) / injectionL) * 100
    }
    
    init(followUp: FollowUp, surgery: Surgery) {
        self.followUp = followUp
        self.surgery = surgery
        
        // 既存データで初期化
        _measurementDate = State(initialValue: followUp.measurementDate ?? Date())
        _postOpVectraR = State(initialValue: followUp.postOpVectraR?.stringValue ?? "")
        _postOpVectraL = State(initialValue: followUp.postOpVectraL?.stringValue ?? "")
        _bodyWeight = State(initialValue: followUp.bodyWeight?.stringValue ?? "")
        _notes = State(initialValue: followUp.notes ?? "")
    }
    
    var body: some View {
        content
            .id(refreshID)  // ✅ 追加: リフレッシュ時にViewを再生成
            .frame(minWidth: 700, idealWidth: 800, maxWidth: 1200,
                   minHeight: 650, idealHeight: 750, maxHeight: 1000)
    }
    
    private var content: some View {
        Form {
            // ✅ 追加: リロードボタンセクション
            Section {
                HStack {
                    Spacer()
                    Button(action: {
                        refreshID = UUID()
                    }) {
                        Label("ウィンドウサイズを再調整", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .font(.caption)
                }
            }
            
            // 基本情報セクション
            Section(header: Text("基本情報")) {
                DatePicker("記録日", selection: $measurementDate, displayedComponents: .date)
                
                if surgery.surgeryDate != nil {
                    HStack {
                        Text("術後日数:")
                        Spacer()
                        Text("\(dayAfterSurgery)日")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // 測定値セクション(豊胸系のみ)
            if surgery.surgeryCategory == "豊胸系" {
                Section(header: Text("測定値")) {
                    HStack {
                        Text("Vectra R (cc):")
                        TextField("右側測定値", text: $postOpVectraR)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        
                        if let rate = retentionRateR {
                            Text(String(format: "残存率: %.1f%%", rate))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    HStack {
                        Text("Vectra L (cc):")
                        TextField("左側測定値", text: $postOpVectraL)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 120)
                        
                        if let rate = retentionRateL {
                            Text(String(format: "残存率: %.1f%%", rate))
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // 体重セクション
            Section(header: Text("体重")) {
                HStack {
                    Text("体重 (kg):")
                    TextField("体重", text: $bodyWeight)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                }
            }
            
            // メモセクション
            Section(header: Text("メモ")) {
                TextEditor(text: $notes)
                    .frame(minHeight: 100, maxHeight: 200)
                    .border(Color.gray.opacity(0.2), width: 1)
            }
            
            // 保存・キャンセルボタン
            HStack {
                Spacer()
                
                Button("キャンセル") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Button("保存") {
                    saveFollowUp()
                }
                .keyboardShortcut(.return)
                .buttonStyle(.borderedProminent)
            }
            .padding(.top)
        }
        .padding()
        .alert("入力エラー", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveFollowUp() {
        // バリデーション
        if measurementDate > Date() {
            alertMessage = "記録日は未来の日付を設定できません"
            showAlert = true
            return
        }
        
        // Vectra値のバリデーション
        if !postOpVectraR.isEmpty {
            guard let vectraR = Double(postOpVectraR), vectraR >= 0 else {
                alertMessage = "Vectra R の値が不正です"
                showAlert = true
                return
            }
        }
        
        if !postOpVectraL.isEmpty {
            guard let vectraL = Double(postOpVectraL), vectraL >= 0 else {
                alertMessage = "Vectra L の値が不正です"
                showAlert = true
                return
            }
        }
        
        // 体重のバリデーション
        if !bodyWeight.isEmpty {
            guard let weight = Double(bodyWeight), weight > 0 else {
                alertMessage = "体重の値が不正です"
                showAlert = true
                return
            }
        }
        
        // 保存処理
        followUp.measurementDate = measurementDate
        followUp.postOpVectraR = postOpVectraR.isEmpty ? nil : NSNumber(value: Double(postOpVectraR)!)
        followUp.postOpVectraL = postOpVectraL.isEmpty ? nil : NSNumber(value: Double(postOpVectraL)!)
        followUp.bodyWeight = bodyWeight.isEmpty ? nil : NSNumber(value: Double(bodyWeight)!)
        followUp.notes = notes.isEmpty ? nil : notes
        
        // タイミングの自動設定
        if let surgeryDate = surgery.surgeryDate {
            let days = Calendar.current.dateComponents([.day], from: surgeryDate, to: measurementDate).day ?? 0
            followUp.timing = "\(days)日後"
        }
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            alertMessage = "保存に失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

struct EditFollowUpView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let surgery = Surgery(context: context)
        surgery.surgeryCategory = "豊胸系"
        surgery.surgeryDate = Date()
        surgery.setValue(250.0, forKey: "injectionVolumeR")
        surgery.setValue(250.0, forKey: "injectionVolumeL")
        surgery.setValue(200.0, forKey: "preOpVectraR")
        surgery.setValue(200.0, forKey: "preOpVectraL")
        
        let followUp = FollowUp(context: context)
        followUp.id = UUID()
        followUp.measurementDate = Date()
        followUp.timing = "1ヶ月後"
        followUp.notes = "順調に回復"
        followUp.postOpVectraR = NSNumber(value: 240.0)
        followUp.postOpVectraL = NSNumber(value: 235.0)
        followUp.bodyWeight = NSNumber(value: 52.5)
        followUp.surgery = surgery
        
        return EditFollowUpView(followUp: followUp, surgery: surgery)
            .environment(\.managedObjectContext, context)
    }
}
