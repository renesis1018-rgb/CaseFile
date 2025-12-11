import SwiftUI
import CoreData
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var manager = CSVImporterManager()
    @State private var showFilePicker = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            // ヘッダー
            HStack {
                Text("CSVデータインポート")
                    .font(.title)
                    .fontWeight(.bold)
                
                Spacer()
                
                Button("閉じる") {
                    dismiss()
                }
            }
            .padding()
            
            if manager.isImporting {
                // インポート中の表示
                VStack(spacing: 20) {
                    ProgressView(value: manager.importProgress) {
                        Text(manager.currentStep)
                            .font(.headline)
                    }
                    .progressViewStyle(.linear)
                    
                    Text("\(Int(manager.importProgress * 100))%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            } else {
                // インポートボタン
                VStack(spacing: 15) {
                    Button(action: {
                        showFilePicker = true
                    }) {
                        Label("CSVファイルを選択", systemImage: "doc.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    if let result = manager.importResult {
                        // インポート結果
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("成功: \(result.success)件")
                            }
                            
                            if result.failed > 0 {
                                HStack {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                    Text("失敗: \(result.failed)件")
                                }
                            }
                            
                            if !result.errors.isEmpty {
                                Divider()
                                Text("エラー詳細:")
                                    .font(.headline)
                                ForEach(result.errors, id: \.self) { error in
                                    Text("• \(error)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .padding()
            }
            
            Spacer()
            
            // 使用方法
            VStack(alignment: .leading, spacing: 10) {
                Text("インポート方法")
                    .font(.headline)
                
                Text("1. CSVファイルを選択")
                Text("2. 自動的に患者情報、手術情報、検査データがインポートされます")
                Text("3. インポート結果を確認")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                startImport(from: url)
            case .failure(let error):
                alertMessage = "ファイル選択エラー: \(error.localizedDescription)"
                showAlert = true
            }
        }
        .alert("エラー", isPresented: $showAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func startImport(from url: URL) {
        Task {
            do {
                manager.isImporting = true
                manager.currentStep = "CSVファイルを読み込み中..."
                manager.importProgress = 0.3
                
                try await Task.sleep(nanoseconds: 500_000_000) // 0.5秒待機
                
                manager.currentStep = "データをインポート中..."
                manager.importProgress = 0.6
                
                try manager.importPatientData(from: url, context: viewContext)
                
                manager.importProgress = 1.0
                manager.currentStep = "完了"
                
                manager.importResult = ImportResult(success: 1, failed: 0, errors: [])
                manager.isImporting = false
                
            } catch {
                manager.isImporting = false
                manager.importResult = ImportResult(success: 0, failed: 1, errors: [error.localizedDescription])
                alertMessage = "インポートエラー: \(error.localizedDescription)"
                showAlert = true
            }
        }
    }
}

#Preview {
    CSVImportView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
