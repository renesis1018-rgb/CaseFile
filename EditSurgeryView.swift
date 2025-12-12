//
//  EditSurgeryView.swift
//  CaseFile
//
//  手術情報編集画面
//

import SwiftUI
import CoreData

struct EditSurgeryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var surgery: Surgery
    let context: NSManagedObjectContext
    
    @State private var notes: String = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報（編集不可）")) {
                    if let date = surgery.surgeryDate {
                        HStack {
                            Text("手術日")
                            Spacer()
                            Text(formatDate(date))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack {
                        Text("カテゴリ")
                        Spacer()
                        Text(surgery.surgeryCategory ?? "未設定")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("術式")
                        Spacer()
                        Text(surgery.surgeryType ?? "未設定")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("備考")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 150)
                }
                
                Section {
                    Text("※ 手術の詳細情報を変更する場合は、手術を削除して再登録してください")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .formStyle(.grouped)
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
                notes = surgery.notes ?? ""
            }
        }
    }
    
    private func saveChanges() {
        surgery.notes = notes.isEmpty ? nil : notes
        
        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            showError = true
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Preview

#Preview {
    EditSurgeryView(
        surgery: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Surgery }) as! Surgery,
        context: PersistenceController.preview.container.viewContext
    )
}
