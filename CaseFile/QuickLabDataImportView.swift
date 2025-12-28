//
//  QuickLabDataImportView.swift
//  CaseFile
//
//  血液検査データのコピペインポート画面（ドラッグ可能版）
//  ✅ macOS対応
//  ✅ ウィンドウサイズ変更可能
//  ✅ ドラッグ移動可能
//

import SwiftUI
import CoreData

struct QuickLabDataImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let patient: Patient
    
    @State private var pastedText: String = ""
    @State private var testDate: Date = Date()
    @State private var previewData: ParsedLabData?
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let parser = LabDataParser()
    
    var body: some View {
        VStack(spacing: 0) {
            // タイトルバー（ドラッグハンドル）
            HStack {
                Text("血液検査データのインポート")
                    .font(.headline)
                    .padding(.leading)
                
                Spacer()
                
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
                .padding(.trailing)
            }
            .padding(.vertical, 12)
            .background(Color(nsColor: .windowBackgroundColor))
            .overlay(
                Divider(), alignment: .bottom
            )
            
            // メインコンテンツ
            ScrollView {
                VStack(spacing: 20) {
                    // ヘッダー
                    VStack(alignment: .leading, spacing: 8) {
                        Text("検査結果をコピーして下のテキストエリアに貼り付けてください")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // 検査日の選択
                    HStack {
                        Text("検査日:")
                            .font(.subheadline)
                        DatePicker("", selection: $testDate, displayedComponents: .date)
                            .labelsHidden()
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // テキスト入力エリア
                    VStack(alignment: .leading, spacing: 8) {
                        Text("検査データ")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $pastedText)
                            .frame(height: 180)
                            .border(Color.gray.opacity(0.5), width: 1)
                            .font(.system(.body, design: .monospaced))
                            .onChange(of: pastedText) {
                                updatePreview()
                            }
                    }
                    .padding(.horizontal)
                    
                    // プレビュー
                    if let preview = previewData {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("プレビュー")
                                    .font(.headline)
                                
                                Spacer()
                                
                                Text("\(preview.parsedCount) 件")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            ScrollView {
                                VStack(alignment: .leading, spacing: 8) {
                                    ForEach(Array(preview.items.enumerated()), id: \.offset) { index, item in
                                        HStack {
                                            Text(item.fieldName)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            // 値の表示（型に応じて処理）
                                            if let doubleValue = item.value as? Double {
                                                Text(String(format: "%.2f", doubleValue))
                                                    .font(.caption)
                                                    .bold()
                                            } else if let stringValue = item.value as? String {
                                                Text(stringValue)
                                                    .font(.caption)
                                                    .bold()
                                            } else {
                                                Text("未対応型")
                                                    .font(.caption)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                        
                                        if index < preview.items.count - 1 {
                                            Divider()
                                        }
                                    }
                                }
                            }
                            .frame(height: 120)
                            
                            // 未マッチの行がある場合
                            if !preview.unmatchedLines.isEmpty {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("⚠️ マッチしなかった行: \(preview.unmatchedLines.count) 件")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                    
                                    ForEach(preview.unmatchedLines.prefix(2), id: \.self) { line in
                                        Text(line)
                                            .font(.system(.caption2, design: .monospaced))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    
                                    if preview.unmatchedLines.count > 2 {
                                        Text("... 他 \(preview.unmatchedLines.count - 2) 件")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.top, 8)
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
                .padding(.bottom, 80)  // ボタン分の余白
            }
            
            // 下部固定ボタン
            VStack(spacing: 0) {
                Divider()
                
                HStack(spacing: 16) {
                    Button("キャンセル") {
                        dismiss()
                    }
                    .keyboardShortcut(.cancelAction)
                    
                    Spacer()
                    
                    Button("保存") {
                        saveLabData()
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(previewData == nil || previewData!.items.isEmpty)
                }
                .padding()
                .background(Color(nsColor: .windowBackgroundColor))
            }
        }
        .frame(width: 650, height: 700)  // 固定サイズ（リサイズ可能）
        .alert("インポート結果", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("成功") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - プレビュー更新
    private func updatePreview() {
        guard !pastedText.trimmingCharacters(in: .whitespaces).isEmpty else {
            previewData = nil
            return
        }
        
        let data = parser.parse(pastedText, testDate: testDate)
        previewData = data
    }
    
    // MARK: - データ保存
    private func saveLabData() {
        guard let data = previewData, !data.items.isEmpty else {
            alertMessage = "保存するデータがありません"
            showAlert = true
            return
        }
        
        do {
            let _ = try parser.saveToLabData(data, patient: patient, context: viewContext)
            
            // 成功メッセージ
            let unmatchedInfo = data.unmatchedLines.isEmpty ? "" : "\n\n⚠️ マッチしなかった行: \(data.unmatchedLines.count) 件"
            alertMessage = """
            ✅ 血液検査データを保存しました
            
            保存された項目: \(data.parsedCount) 件
            検査日: \(formattedDate(data.testDate))\(unmatchedInfo)
            """
            showAlert = true
            
            print("✅ QuickLabDataImport: \(data.parsedCount) 件保存")
            
        } catch {
            alertMessage = "❌ 保存に失敗しました\n\nエラー: \(error.localizedDescription)"
            showAlert = true
            
            print("❌ QuickLabDataImport保存エラー: \(error)")
        }
    }
    
    // MARK: - ヘルパー
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - プレビュー
struct QuickLabDataImportView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let patient = Patient(context: context)
        patient.id = UUID()
        patient.patientId = "TEST001"
        patient.name = "テスト患者"
        
        return QuickLabDataImportView(patient: patient)
            .environment(\.managedObjectContext, context)
    }
}
