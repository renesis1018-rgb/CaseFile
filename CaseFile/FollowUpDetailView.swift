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
    @FocusState private var isFocused: Bool  // ✅ 追加: フォーカス管理
    
    // MARK: - リロード処理
    private func reloadFollowUpData() {
        // Core Dataから最新データを再取得
        viewContext.refresh(followUp, mergeChanges: true)
        viewContext.refresh(surgery, mergeChanges: true)
        
        // UIも更新
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
                    
                    // 測定値セクション(豊胸系のみ)
                    if surgery.surgeryCategory == "豊胸系" {
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
                    
                    // メモセクション
                    if let notes = followUp.notes, !notes.isEmpty {
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
                    
                    Spacer()
                }
                .padding()
            }
        }
        .id(refreshID)
        .frame(minWidth: 700, idealWidth: 800, maxWidth: 1000,
               minHeight: 600, idealHeight: 700, maxHeight: 900)
        .focusable()  // ✅ 追加: キーボードイベントを受け取れるようにする
        .focused($isFocused)  // ✅ 追加: フォーカス管理
        .onAppear {
            isFocused = true  // ✅ 追加: 表示時に自動フォーカス
        }
        .onKeyPress(characters: .alphanumerics) { press in  // ✅ 修正
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
        
        let followUp = FollowUp(context: context)
        followUp.id = UUID()
        followUp.measurementDate = Date()
        followUp.timing = "1ヶ月後"
        followUp.notes = "順調に回復しています"
        followUp.postOpVectraR = NSNumber(value: 250.0)
        followUp.postOpVectraL = NSNumber(value: 245.0)
        followUp.bodyWeight = NSNumber(value: 52.5)
        followUp.surgery = surgery
        
        return FollowUpDetailView(followUp: followUp, surgery: surgery)
            .environment(\.managedObjectContext, context)
            .frame(width: 800, height: 700)
    }
}
