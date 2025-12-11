//
//  PatientDetailView.swift
//  CaseFile
//
//  患者詳細画面（手術履歴一覧）
//

import SwiftUI
import CoreData

struct PatientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var patient: Patient
    
    @State private var showEditPatient = false
    @State private var showAddSurgery = false
    @State private var showAddLabData = false
    @State private var showDeleteConfirm = false
    
    // MARK: - Computed
    
    private var surgeries: [Surgery] {
        let surgerySet = patient.surgeries as? Set<Surgery> ?? []
        return surgerySet.sorted { $0.surgeryDate ?? Date.distantPast > $1.surgeryDate ?? Date.distantPast }
    }
    
    private var labData: [LabData] {
        let labDataSet = patient.labData as? Set<LabData> ?? []
        return labDataSet.sorted { $0.testDate ?? Date.distantPast > $1.testDate ?? Date.distantPast }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 患者基本情報
                patientInfoSection
                
                Divider()
                
                // 手術履歴
                surgeryHistorySection
                
                Divider()
                
                // 血液検査履歴
                labDataSection
            }
            .padding()
        }
        .navigationTitle(patient.patientId ?? "患者詳細")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button(action: { showEditPatient = true }) {
                        Label("患者情報編集", systemImage: "pencil")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showDeleteConfirm = true }) {
                        Label("患者削除", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showEditPatient) {
            EditPatientView(patient: patient)
                .frame(minWidth: 500, minHeight: 500)  // ← 🆕 追加
        }
        .sheet(isPresented: $showAddSurgery) {
            AddSurgeryView(patient: patient, context: viewContext)
        }
        .sheet(isPresented: $showAddLabData) {
            AddLabDataView(patient: patient, context: viewContext)
        }
        .alert("患者削除の確認", isPresented: $showDeleteConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                deletePatient()
            }
        } message: {
            Text("この患者と関連する全てのデータ（手術、写真、経過情報）が削除されます。この操作は取り消せません。")
        }
    }
    
    // MARK: - Patient Info Section
    
    private var patientInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("患者基本情報")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showEditPatient = true }) {
                    Label("編集", systemImage: "pencil")
                        .font(.system(size: 13))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            VStack(spacing: 8) {
                InfoRow(label: "患者ID", value: patient.patientId ?? "未設定")
                InfoRow(label: "年齢", value: "\(patient.age ?? 0)歳")
                InfoRow(label: "性別", value: patient.gender ?? "未設定")
                
                if let name = patient.name, !name.isEmpty {
                    InfoRow(label: "氏名", value: name)
                }
                
                if let contact = patient.contactInfo, !contact.isEmpty {
                    InfoRow(label: "連絡先", value: contact)
                }
                
                if let registeredDate = patient.registeredDate {
                    InfoRow(label: "登録日", value: formatDate(registeredDate))
                }
                
                if let notes = patient.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("備考")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.system(size: 13))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Surgery History Section
    
    private var surgeryHistorySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("手術履歴")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(surgeries.count)件")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showAddSurgery = true }) {
                    Label("新規手術登録", systemImage: "plus")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if surgeries.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "stethoscope")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("手術履歴がありません")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                .cornerRadius(10)
            } else {
                VStack(spacing: 8) {
                    ForEach(surgeries, id: \.objectID) { surgery in
                        NavigationLink(destination: SurgeryDetailView(surgery: surgery)) {
                            SurgeryRowView(surgery: surgery)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Lab Data Section
    
    private var labDataSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("血液検査履歴")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(labData.count)件")
                    .font(.title3)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: { showAddLabData = true }) {
                    Label("血液検査登録", systemImage: "plus")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            
            if labData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cross.vial")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text("血液検査データがありません")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
                .cornerRadius(10)
            } else {
                VStack(spacing: 8) {
                    ForEach(labData, id: \.objectID) { lab in
                        NavigationLink(destination: LabDataDetailView(labData: lab)) {
                            LabDataRowView(labData: lab)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func deletePatient() {
        viewContext.delete(patient)
        
        do {
            try viewContext.save()
        } catch {
            print("⚠️ 患者削除エラー: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Surgery Row View

struct SurgeryRowView: View {
    let surgery: Surgery
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Text(surgery.surgeryCategory ?? "未分類")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(categoryColor.opacity(0.2))
                        .foregroundColor(categoryColor)
                        .cornerRadius(4)
                    
                    Text(surgery.surgeryType ?? "術式不明")
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                }
                
                if let date = surgery.surgeryDate {
                    Text(formatDate(date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }
    
    private var categoryColor: Color {
        switch surgery.surgeryCategory {
        case "豊胸系": return .pink
        case "目元": return .blue
        case "脂肪吸引": return .orange
        default: return .gray
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - Lab Data Row View

struct LabDataRowView: View {
    let labData: LabData
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("血液検査")
                    .font(.system(size: 13, weight: .semibold))
                
                if let date = labData.testDate {
                    Text(formatDate(date))
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
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
    NavigationView {
        PatientDetailView(patient: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Patient }) as! Patient)
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
