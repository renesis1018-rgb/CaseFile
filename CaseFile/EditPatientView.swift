//
//  EditPatientView.swift
//  CaseFile
//
//  患者情報編集画面
//

import SwiftUI
import CoreData

struct EditPatientView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var patient: Patient
    
    // MARK: - State
    
    @State private var patientId: String = ""
    @State private var age: String = ""
    @State private var gender: String = "女性"
    @State private var name: String = ""
    @State private var contactInfo: String = ""
    @State private var notes: String = ""
    
    @State private var showError = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case patientId, age, name, contactInfo, notes
    }
    
    let genderOptions = ["女性", "男性", "その他"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    // 患者ID
                    HStack {
                        Text("患者ID")
                            .frame(width: 100, alignment: .leading)
                        TextField("例: P-0001", text: $patientId)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .patientId)
                    }
                    
                    // 年齢
                    HStack {
                        Text("年齢")
                            .frame(width: 100, alignment: .leading)
                        TextField("例: 28", text: $age)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .age)
                        Text("歳")
                    }
                    
                    // 性別
                    HStack {
                        Text("性別")
                            .frame(width: 100, alignment: .leading)
                        Picker("", selection: $gender) {
                            ForEach(genderOptions, id: \.self) { option in
                                Text(option).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }
                
                Section(header: Text("詳細情報（任意）")) {
                    // 氏名
                    HStack {
                        Text("氏名")
                            .frame(width: 100, alignment: .leading)
                        TextField("例: 山田 花子", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .name)
                    }
                    
                    // 連絡先
                    HStack {
                        Text("連絡先")
                            .frame(width: 100, alignment: .leading)
                        TextField("例: 03-1234-5678", text: $contactInfo)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .contactInfo)
                    }
                }
                
                Section(header: Text("備考（任意）")) {
                    TextEditor(text: $notes)
                        .frame(minHeight: 100)
                        .focused($focusedField, equals: .notes)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("患者情報編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        savePatient()
                    }
                    .keyboardShortcut(.return, modifiers: .command)
                }
            }
            .alert("入力エラー", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadPatientData()
            }
        }
    }
    
    // MARK: - Actions
    
    private func loadPatientData() {
        patientId = patient.patientId ?? ""
        age = "(patient.age?.int16Value ?? 0)"
        gender = patient.gender ?? "女性"
        name = patient.name ?? ""
        contactInfo = patient.contactInfo ?? ""
        notes = patient.notes ?? ""
    }
    
    private func savePatient() {
        // バリデーション
        guard !patientId.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "患者IDを入力してください"
            showError = true
            return
        }
        
        guard let ageValue = Int16(age), ageValue > 0, ageValue <= 150 else {
            errorMessage = "年齢は1〜150の数値で入力してください"
            showError = true
            return
        }
        
        // 患者ID重複チェック（自分自身を除く）
        if PersistenceController.shared.isPatientIdDuplicate(patientId, excluding: patient) {
            errorMessage = "この患者IDは既に使用されています"
            showError = true
            return
        }
        
        // 保存
        patient.patientId = patientId.trimmingCharacters(in: .whitespaces)
        patient.age = NSNumber(value: ageValue)
        patient.gender = gender
        patient.name = name.isEmpty ? nil : name
        patient.contactInfo = contactInfo.isEmpty ? nil : contactInfo
        patient.notes = notes.isEmpty ? nil : notes
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - Preview

#Preview {
    EditPatientView(patient: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Patient }) as! Patient)
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
