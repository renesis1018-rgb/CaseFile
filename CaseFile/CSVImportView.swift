import SwiftUI
import UniformTypeIdentifiers

struct CSVImportView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var importer: CSVImporterManager
    @State private var isFileImporterPresented = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init() {
        // ✅ 修正: Persistence.shared を使用 (アプリと同じContext)
        let tempContext = Persistence.shared.container.viewContext
        _importer = StateObject(wrappedValue: CSVImporterManager(viewContext: tempContext))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("データインポート")
                .font(.largeTitle)
                .padding()
            
            if importer.isImporting {
                ProgressView("インポート中...")
                    .progressViewStyle(CircularProgressViewStyle())
            } else {
                Button(action: {
                    isFileImporterPresented = true
                }) {
                    Label("Excelファイルを選択", systemImage: "doc.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
                
                Button(action: {
                    loadSampleDataFromBundle()
                }) {
                    Label("サンプルデータをインポート", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            
            if !importer.importedCounts.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("インポート結果:")
                        .font(.headline)
                    
                    ForEach(Array(importer.importedCounts.keys.sorted()), id: \.self) { key in
                        HStack {
                            Text("\(key):")
                            Spacer()
                            Text("\(importer.importedCounts[key] ?? 0) 件")
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            if !importer.errorMessages.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("エラー:")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    ForEach(importer.errorMessages, id: \.self) { error in
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .fileImporter(
            isPresented: $isFileImporterPresented,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                guard let fileURL = urls.first else { return }
                importer.importExcelFile(at: fileURL)
            case .failure(let error):
                alertMessage = "ファイル選択エラー: \(error.localizedDescription)"
                showingAlert = true
            }
        }
        .alert("エラー", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func loadSampleDataFromBundle() {
        guard let bundleURL = Bundle.main.url(forResource: "test_import_sample_data", withExtension: "xlsx") else {
            alertMessage = "サンプルファイルが見つかりません"
            showingAlert = true
            return
        }
        
        importer.importExcelFile(at: bundleURL)
    }
}
