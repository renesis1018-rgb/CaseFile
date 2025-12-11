import SwiftUI
import CoreData

struct SurgeryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var surgery: Surgery
    
    @State private var showEditView = false
    @State private var showDeleteAlert = false
    @State private var showAddFollowUpView = false
    
    var body: some View {
        TabView {
            // 手術情報タブ
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    surgeryInfoSection
                }
                .padding()
            }
            .tabItem {
                Label("手術情報", systemImage: "doc.text")
            }
            
            // 写真管理タブ
            PhotoManagementView(surgery: surgery)
                .tabItem {
                    Label("写真管理", systemImage: "photo.on.rectangle.angled")
                }
            
            // 経過情報タブ
            followUpTab
                .tabItem {
                    Label("経過情報", systemImage: "chart.line.uptrend.xyaxis")
                }
        }
        .navigationTitle(surgery.patient?.name ?? "患者名不明")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showEditView = true }) {
                    Label("編集", systemImage: "pencil")
                }
            }
            ToolbarItem(placement: .automatic) {
                Button(role: .destructive, action: { showDeleteAlert = true }) {
                    Label("削除", systemImage: "trash")
                        .foregroundColor(.red)
                }
            }
        }
        .sheet(isPresented: $showEditView) {
            EditSurgeryView(surgery: surgery, context: viewContext)
        }
        .sheet(isPresented: $showAddFollowUpView) {
            AddFollowUpView(surgery: surgery)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("手術データの削除", isPresented: $showDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                deleteSurgery()
            }
        } message: {
            Text("この手術データを削除しますか？")
        }
    }
    
    // MARK: - 手術情報セクション
    private var surgeryInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // 手術日
            if let surgeryDate = surgery.surgeryDate {
                infoRow(label: "手術日", value: formattedDate(surgeryDate))
            }
            
            // 手術カテゴリー
            if let category = surgery.surgeryCategory {
                infoRow(label: "カテゴリー", value: category)
            }
            
            // 手術タイプ
            if let type = surgery.surgeryType {
                infoRow(label: "手術タイプ", value: type)
            }
            
            // Procedure（手術内容の詳細）
            if let procedure = surgery.procedure, !procedure.isEmpty {
                infoRow(label: "手術内容", value: procedure)
            }
            
            // 備考
            if let notes = surgery.notes, !notes.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("備考")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text(notes)
                        .font(.body)
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    // MARK: - 情報行ヘルパー
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 120, alignment: .leading)
            
            Text(value)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
    
    // MARK: - 経過情報タブ
    private var followUpTab: some View {
        VStack {
            // 経過情報登録ボタン
            Button(action: { showAddFollowUpView = true }) {
                Label("経過情報登録", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .shadow(radius: 2)
            }
            .padding(.horizontal)
            .padding(.top, 12)
            
            // 経過情報リスト
            if let followUps = surgery.followUps?.allObjects as? [FollowUp], !followUps.isEmpty {
                List {
                    ForEach(followUpsSorted(followUps), id: \.id) { followUp in
                        FollowUpRowView(followUp: followUp)
                    }
                    .onDelete(perform: deleteFollowUp)
                }
                .listStyle(PlainListStyle())
            } else {
                Spacer()
                Text("経過情報がまだ登録されていません")
                    .foregroundColor(.secondary)
                    .font(.headline)
                Spacer()
            }
        }
    }
    
    // MARK: - 削除処理
    private func deleteSurgery() {
        viewContext.delete(surgery)
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            print("❌ 手術データ削除エラー: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 経過情報の削除
    private func deleteFollowUp(at offsets: IndexSet) {
        guard let followUps = surgery.followUps?.allObjects as? [FollowUp] else { return }
        let sortedFollowUps = followUpsSorted(followUps)
        
        offsets.forEach { index in
            let followUp = sortedFollowUps[index]
            viewContext.delete(followUp)
        }
        
        do {
            try viewContext.save()
        } catch {
            print("❌ 経過情報削除エラー: \(error.localizedDescription)")
        }
    }
    
    // MARK: - 経過情報ソート（新しい順）
    private func followUpsSorted(_ followUps: [FollowUp]) -> [FollowUp] {
        followUps.sorted { ($0.followUpDate ?? Date.distantPast) > ($1.followUpDate ?? Date.distantPast) }
    }
    
    // MARK: - 日付フォーマット
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - 経過情報行ビュー
struct FollowUpRowView: View {
    let followUp: FollowUp
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 日付
            if let date = followUp.followUpDate {
                Text(formattedDate(date))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // 備考プレビュー
            if let notes = followUp.notes, !notes.isEmpty {
                Text(notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd (E)"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - プレビュー
struct SurgeryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        
        let patient = Patient(context: context)
        patient.id = UUID()
        patient.name = "山田 太郎"
        
        let surgery = Surgery(context: context)
        surgery.id = UUID()
        surgery.surgeryDate = Date()
        surgery.surgeryCategory = "豊胸系"
        surgery.surgeryType = "脂肪注入"
        surgery.procedure = "脂肪注入 (ピュアグラフト)"
        surgery.patient = patient
        
        return NavigationView {
            SurgeryDetailView(surgery: surgery)
                .environment(\.managedObjectContext, context)
        }
    }
}
