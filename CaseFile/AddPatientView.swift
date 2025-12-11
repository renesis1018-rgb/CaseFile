//
//  AddPatientView.swift
//  CaseFile
//

import SwiftUI
import CoreData

struct AddPatientView: View {
    @Environment(\.dismiss) private var dismiss
    let context: NSManagedObjectContext
    
    @State private var patientId = ""
    @State private var age = ""
    @State private var gender = "女性"
    @State private var contactInfo = ""
    @State private var notes = ""
    @State private var registeredDate = Date()
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("新規患者登録")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // フォーム本体
            Form {
                Section(header: Text("基本情報")) {
                    HStack {
                        Text("患者ID")
                            .frame(width: 100, alignment: .trailing)
                        
                        TextField("患者ID（任意の数字を入力）", text: $patientId)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                    }
                    
                    HStack {
                        Text("年齢")
                            .frame(width: 100, alignment: .trailing)
                        
                        TextField("年齢", text: $age)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 100)
                    }
                    .onChange(of: age) {
                        age = age.filter { $0.isNumber }
                    }
                    
                    HStack {
                        Text("性別")
                            .frame(width: 100, alignment: .trailing)
                        
                        Picker("", selection: $gender) {
                            Text("女性").tag("女性")
                            Text("男性").tag("男性")
                        }
                        .pickerStyle(.segmented)
                        .frame(maxWidth: 300, alignment: .leading)
                    }
                    
                    HStack {
                        Text("登録日")
                            .frame(width: 100, alignment: .trailing)
                        
                        DatePicker("", selection: $registeredDate, displayedComponents: .date)
                            .labelsHidden()
                            .frame(maxWidth: 300)
                    }
                }
                
                Section(header: Text("連絡先・備考")) {
                    HStack {
                        Text("連絡先")
                            .frame(width: 100, alignment: .trailing)
                        
                        TextField("電話番号・メールアドレスなど", text: $contactInfo)
                            .textFieldStyle(.roundedBorder)
                            .frame(maxWidth: 300)
                    }
                    
                    VStack(alignment: .leading) {
                        HStack {
                            Text("備考")
                                .frame(width: 100, alignment: .trailing)
                            
                            TextEditor(text: $notes)
                                .frame(maxWidth: 300, minHeight: 100)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .padding()
            
            Divider()
            
            // フッター（ボタン）
            HStack {
                Spacer()
                Button("キャンセル") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Button("保存") {
                    savePatient()
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(width: 700, height: 600)
        .alert("入力エラー", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }
    
    private func savePatient() {
        // バリデーション: 患者IDのみ必須
        let trimmedId = patientId.trimmingCharacters(in: .whitespaces)
        
        if trimmedId.isEmpty {
            showAlert("エラー", "患者IDを入力してください")
            return
        }
        
        // 🆕 患者ID重複チェック
        if isPatientIdDuplicate(trimmedId) {
            showAlert("エラー", "この患者IDは既に使用されています")
            return
        }
        
        // 年齢のバリデーション
        let ageValue: Int16
        if age.isEmpty {
            ageValue = 0
        } else if let parsedAge = Int16(age), parsedAge > 0, parsedAge <= 150 {
            ageValue = parsedAge
        } else {
            showAlert("エラー", "年齢は1〜150の数値で入力してください")
            return
        }
        
        let newPatient = Patient(context: context)
        newPatient.id = UUID()
        newPatient.patientId = trimmedId
        newPatient.name = "患者\(trimmedId)"  // 名前は患者IDベースで自動生成
        newPatient.age = NSNumber(value: ageValue)
        newPatient.gender = gender
        newPatient.contactInfo = contactInfo.isEmpty ? nil : contactInfo
        newPatient.notes = notes.isEmpty ? nil : notes
        newPatient.registeredDate = registeredDate
        
        do {
            try context.save()
            print("✅ 新規患者を登録しました: ID=\(trimmedId)")
            dismiss()
        } catch {
            showAlert("保存エラー", "患者情報の保存に失敗しました: \(error.localizedDescription)")
        }
    }
    
    // 🆕 患者ID重複チェック
    private func isPatientIdDuplicate(_ id: String) -> Bool {
        let request: NSFetchRequest<Patient> = Patient.fetchRequest()
        request.predicate = NSPredicate(format: "patientId == %@", id)
        
        do {
            let count = try context.count(for: request)
            return count > 0
        } catch {
            print("⚠️ 重複チェックエラー: \(error)")
            return false
        }
    }
    
    private func showAlert(_ title: String, _ message: String) {
        alertMessage = message
        showAlert = true
    }
}
