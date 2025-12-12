//
//  SurgeryDetailView.swift
//  CaseFile
//
//  手術詳細画面（タブ表示: 手術情報・写真管理・経過情報）
//  Phase 3改善版: 全属性の完全表示対応 + ツールバー修正
//

import SwiftUI
import CoreData

struct SurgeryDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @ObservedObject var surgery: Surgery
    
    @State private var selectedTab = 0
    @State private var showEditSurgery = false
    @State private var showDeleteConfirm = false
    @State private var showAddFollowUp = false
    
    var body: some View {
        VStack(spacing: 0) {
            // カスタムヘッダー（ツールバーの代わり）
            customHeader
            
            Divider()
            
            // タブビュー
            TabView(selection: $selectedTab) {
                // タブ1: 手術情報
                surgeryInfoTab
                    .tabItem {
                        Label("手術情報", systemImage: "heart.text.square")
                    }
                    .tag(0)
                
                // タブ2: 写真管理
                PhotoManagementView(surgery: surgery)
                    .tabItem {
                        Label("写真管理", systemImage: "photo.on.rectangle")
                    }
                    .tag(1)
                
                // タブ3: 経過情報
                followUpListTab
                    .tabItem {
                        Label("経過情報", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(2)
            }
        }
        .frame(minWidth: 900, idealWidth: 1000, minHeight: 750)
        .navigationTitle(surgery.surgeryCategory ?? "手術詳細")
        .sheet(isPresented: $showEditSurgery) {
            EditSurgeryView(surgery: surgery, context: viewContext)
        }
        .sheet(isPresented: $showAddFollowUp) {
            AddFollowUpView(surgery: surgery)
                .environment(\.managedObjectContext, viewContext)
        }
        .alert("手術削除の確認", isPresented: $showDeleteConfirm) {
            Button("キャンセル", role: .cancel) {}
            Button("削除", role: .destructive) {
                deleteSurgery()
            }
        } message: {
            Text("この手術と関連する全てのデータ（写真、経過情報）が削除されます。この操作は取り消せません。")
        }
    }
    
    // MARK: - カスタムヘッダー
    private var customHeader: some View {
        HStack {
            Spacer()
            
            // 手術情報編集ボタン
            Button(action: { showEditSurgery = true }) {
                Label("手術情報編集", systemImage: "pencil")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            
            // 手術削除ボタン
            Button(action: { showDeleteConfirm = true }) {
                Label("手術削除", systemImage: "trash")
                    .font(.system(size: 13))
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
            .foregroundColor(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.3))
    }
    
    // MARK: - 手術情報タブ
    private var surgeryInfoTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 基本情報
                basicInfoSection
                
                Divider()
                
                // 患者情報（豊胸系のみ）
                if surgery.surgeryCategory == "豊胸系" {
                    patientInfoSection
                    Divider()
                }
                
                // 術前患者状態
                if shouldShowPatientStatus {
                    patientStatusSection
                    Divider()
                }
                
                // 術前測定値（豊胸系のみ）
                if surgery.surgeryCategory == "豊胸系" {
                    preOpMeasurementsSection
                    Divider()
                }
                
                // カテゴリー別詳細
                categorySpecificSection
                
                // 備考
                if let notes = surgery.notes, !notes.isEmpty {
                    Divider()
                    notesSection
                }
            }
            .padding()
        }
    }
    
    // MARK: - 基本情報セクション
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本情報")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let date = surgery.surgeryDate {
                    InfoRow(label: "手術日", value: formatDate(date), labelWidth: 180)
                }
                InfoRow(label: "カテゴリ", value: surgery.surgeryCategory ?? "未設定", labelWidth: 180)
                InfoRow(label: "術式", value: surgery.surgeryType ?? "未設定", labelWidth: 180)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - 患者情報セクション（豊胸系のみ）
    private var patientInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("患者情報（豊胸系）")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                InfoRow(label: "喫煙歴", value: surgery.smokingHistory ?? "未入力", labelWidth: 180)
                InfoRow(label: "授乳歴", value: surgery.breastfeedingHistory ?? "未入力", labelWidth: 180)
                InfoRow(label: "手術回数", value: surgery.numberOfProcedures?.stringValue ?? "未入力", labelWidth: 180)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - 術前患者状態セクション
    private var patientStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("術前患者状態")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let height = surgery.height {
                    InfoRow(label: "身長", value: String(format: "%.1f cm", height.doubleValue), labelWidth: 180)
                }
                if let weight = surgery.bodyWeight {
                    InfoRow(label: "体重", value: String(format: "%.1f kg", weight.doubleValue), labelWidth: 180)
                }
                if let bmi = surgery.bmi {
                    InfoRow(label: "BMI", value: String(format: "%.1f", bmi.doubleValue), labelWidth: 180)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - 術前測定値セクション（豊胸系のみ）
    private var preOpMeasurementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("術前測定値")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 16) {
                // Vectra測定
                if surgery.preOpVectraR != nil || surgery.preOpVectraL != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Vectra測定値 (cc)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            InfoRow(label: "右", value: surgery.preOpVectraR?.stringValue ?? "未入力", labelWidth: 60)
                            InfoRow(label: "左", value: surgery.preOpVectraL?.stringValue ?? "未入力", labelWidth: 60)
                        }
                    }
                }
                
                // NAC-IMF距離
                if surgery.nacImfRight != nil || surgery.nacImfLeft != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("NAC-IMF距離 (cm)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            InfoRow(label: "右", value: surgery.nacImfRight?.stringValue ?? "未入力", labelWidth: 60)
                            InfoRow(label: "左", value: surgery.nacImfLeft?.stringValue ?? "未入力", labelWidth: 60)
                        }
                    }
                }
                
                // 皮膚厚
                if surgery.skinThicknessRight != nil || surgery.skinThicknessLeft != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("皮膚厚 (mm)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            InfoRow(label: "右", value: surgery.skinThicknessRight?.stringValue ?? "未入力", labelWidth: 60)
                            InfoRow(label: "左", value: surgery.skinThicknessLeft?.stringValue ?? "未入力", labelWidth: 60)
                        }
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - カテゴリー別詳細セクション
    private var categorySpecificSection: some View {
        Group {
            if surgery.surgeryCategory == "豊胸系" {
                if let surgeryType = surgery.surgeryType, surgeryType.contains("脂肪注入") {
                    fatInjectionSection
                } else if let surgeryType = surgery.surgeryType, surgeryType.contains("シリコン") {
                    siliconeSection
                }
            } else if surgery.surgeryCategory == "脂肪吸引" {
                liposuctionSection
            }
        }
    }
    
    // MARK: - 脂肪注入詳細
    private var fatInjectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("脂肪注入詳細")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                // ドナー部位
                InfoRow(label: "ドナー部位", value: surgery.donorSite ?? "未入力", labelWidth: 180)
                if surgery.donorSite == "その他", let other = surgery.donorSiteOther {
                    InfoRow(label: "その他詳細", value: other, labelWidth: 180)
                }
                
                // 層別注入量
                if hasAnyLayeredVolume() {
                    Divider()
                    Text("層別注入量 (cc)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        if surgery.subcutaneousRight != nil || surgery.subcutaneousLeft != nil {
                            HStack(spacing: 16) {
                                Text("皮下").frame(width: 100, alignment: .leading)
                                InfoRow(label: "右", value: surgery.subcutaneousRight?.stringValue ?? "-", labelWidth: 60)
                                InfoRow(label: "左", value: surgery.subcutaneousLeft?.stringValue ?? "-", labelWidth: 60)
                            }
                        }
                        
                        if surgery.subglandularRight != nil || surgery.subglandularLeft != nil {
                            HStack(spacing: 16) {
                                Text("乳腺下").frame(width: 100, alignment: .leading)
                                InfoRow(label: "右", value: surgery.subglandularRight?.stringValue ?? "-", labelWidth: 60)
                                InfoRow(label: "左", value: surgery.subglandularLeft?.stringValue ?? "-", labelWidth: 60)
                            }
                        }
                        
                        if surgery.submuscularRight != nil || surgery.submuscularLeft != nil {
                            HStack(spacing: 16) {
                                Text("筋肉下").frame(width: 100, alignment: .leading)
                                InfoRow(label: "右", value: surgery.submuscularRight?.stringValue ?? "-", labelWidth: 60)
                                InfoRow(label: "左", value: surgery.submuscularLeft?.stringValue ?? "-", labelWidth: 60)
                            }
                        }
                        
                        if surgery.decolletRight != nil || surgery.decolletLeft != nil {
                            HStack(spacing: 16) {
                                Text("デコルテ").frame(width: 100, alignment: .leading)
                                InfoRow(label: "右", value: surgery.decolletRight?.stringValue ?? "-", labelWidth: 60)
                                InfoRow(label: "左", value: surgery.decolletLeft?.stringValue ?? "-", labelWidth: 60)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - シリコン豊胸詳細
    private var siliconeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("シリコン豊胸詳細")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 12) {
                // インプラントサイズ
                if surgery.implantSizeR != nil || surgery.implantSizeL != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("インプラントサイズ (cc)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        HStack(spacing: 16) {
                            InfoRow(label: "右", value: surgery.implantSizeR?.stringValue ?? "未入力", labelWidth: 60)
                            InfoRow(label: "左", value: surgery.implantSizeL?.stringValue ?? "未入力", labelWidth: 60)
                        }
                    }
                }
                
                InfoRow(label: "メーカー", value: surgery.implantManufacturer ?? "未入力", labelWidth: 180)
                InfoRow(label: "切開部位", value: surgery.incisionSite ?? "未入力", labelWidth: 180)
                InfoRow(label: "挿入層", value: surgery.insertionPlane ?? "未入力", labelWidth: 180)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - 脂肪吸引詳細
    private var liposuctionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("脂肪吸引詳細")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                InfoRow(label: "吸引部位", value: surgery.surgeryType ?? "未入力", labelWidth: 180)
                InfoRow(label: "総吸引量", value: surgery.liposuctionVolume != nil ? "\(surgery.liposuctionVolume!.stringValue) cc" : "未入力", labelWidth: 180)
                InfoRow(label: "Aquicell使用", value: surgery.aquicellUsed ?? false, labelWidth: 180)
                InfoRow(label: "Vaser使用", value: surgery.vaserUsed ?? false, labelWidth: 180)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - 備考セクション
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("備考")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(surgery.notes ?? "")
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
                .cornerRadius(10)
        }
    }
    
    // MARK: - 経過情報タブ
    private var followUpListTab: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("経過情報")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button(action: { showAddFollowUp = true }) {
                    Label("経過情報追加", systemImage: "plus")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding()
            
            ScrollView {
                if followUpData.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        Text("経過情報がまだ登録されていません")
                            .font(.title3)
                            .foregroundColor(.secondary)
                        Text("「経過情報追加」ボタンから追加してください")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    VStack(spacing: 12) {
                        ForEach(followUpData, id: \.objectID) { followUp in
                            FollowUpRowView(followUp: followUp)
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Helper Properties
    
    private var followUpData: [FollowUp] {
        let followUpSet = surgery.followUps as? Set<FollowUp> ?? []
        return followUpSet.sorted { 
            ($0.measurementDate ?? Date.distantPast) > ($1.measurementDate ?? Date.distantPast)
        }
    }
    
    private var shouldShowPatientStatus: Bool {
        return surgery.height != nil || surgery.bodyWeight != nil || surgery.bmi != nil
    }
    
    private func hasAnyLayeredVolume() -> Bool {
        return surgery.subcutaneousRight != nil || surgery.subcutaneousLeft != nil ||
               surgery.subglandularRight != nil || surgery.subglandularLeft != nil ||
               surgery.submuscularRight != nil || surgery.submuscularLeft != nil ||
               surgery.decolletRight != nil || surgery.decolletLeft != nil
    }
    
    // MARK: - Actions
    
    private func deleteSurgery() {
        viewContext.delete(surgery)
        
        do {
            try viewContext.save()
        } catch {
            print("⚠️ 手術削除エラー: \(error)")
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年M月d日"
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}

// MARK: - FollowUp Row View

struct FollowUpRowView: View {
    let followUp: FollowUp
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                if let date = followUp.measurementDate {
                    Text(formatDate(date))
                        .font(.system(size: 14, weight: .semibold))
                }
                
                if let notes = followUp.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
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
        SurgeryDetailView(
            surgery: PersistenceController.preview.container.viewContext.registeredObjects.first(where: { $0 is Surgery }) as! Surgery
        )
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
