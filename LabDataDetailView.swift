//
//  LabDataDetailView.swift
//  CaseFile
//
//  血液検査詳細画面
//

import SwiftUI
import CoreData

struct LabDataDetailView: View {
    @ObservedObject var labData: LabData
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 基本情報
                basicInfoSection
                
                Divider()
                
                // 血球系
                bloodCellSection
                
                Divider()
                
                // 生化学系
                biochemistrySection
                
                Divider()
                
                // 肝機能
                liverFunctionSection
                
                Divider()
                
                // 電解質・血糖
                electrolyteGlucoseSection
            }
            .padding()
        }
        .navigationTitle("血液検査結果")
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("検査情報")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let date = labData.testDate {
                    InfoRow(label: "検査日", value: formatDate(date))
                }
                if let patient = labData.patient {
                    InfoRow(label: "患者ID", value: patient.patientId ?? "不明")
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Blood Cell Section
    
    private var bloodCellSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("血球系")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                InfoRow(label: "白血球数 (WBC)", value: labData.wbc, unit: "×10³/μL")
                InfoRow(label: "赤血球数 (RBC)", value: labData.rbc, unit: "×10⁴/μL")
                InfoRow(label: "血色素量 (Hb)", value: labData.hb, unit: "g/dL")
                InfoRow(label: "ヘマトクリット (Ht)", value: labData.hematocrit, unit: "%")
                InfoRow(label: "MCV", value: labData.mcv, unit: "fL")
                InfoRow(label: "MCH", value: labData.mch, unit: "pg")
                InfoRow(label: "MCHC", value: labData.mchc, unit: "%")
                InfoRow(label: "血小板数", value: labData.platelet, unit: "×10⁴/μL")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Biochemistry Section
    
    private var biochemistrySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("生化学系")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                InfoRow(label: "総蛋白 (TP)", value: labData.totalProtein, unit: "g/dL")
                InfoRow(label: "尿酸 (UA)", value: labData.uricAcid, unit: "mg/dL")
                InfoRow(label: "尿素窒素 (UN)", value: labData.urea, unit: "mg/dL")
                InfoRow(label: "クレアチニン (CREA)", value: labData.creatinine, unit: "mg/dL")
                InfoRow(label: "総コレステロール", value: labData.totalCholesterol, unit: "mg/dL")
                InfoRow(label: "中性脂肪 (TG)", value: labData.triglyceride, unit: "mg/dL")
                InfoRow(label: "総ビリルビン", value: labData.totalBilirubin, unit: "mg/dL")
                InfoRow(label: "直接ビリルビン", value: labData.directBilirubin, unit: "mg/dL")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Liver Function Section
    
    private var liverFunctionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("肝機能")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                InfoRow(label: "AST (GOT)", value: labData.ast, unit: "U/L")
                InfoRow(label: "ALT (GPT)", value: labData.alt, unit: "U/L")
                InfoRow(label: "γ-GTP", value: labData.gammaGtp, unit: "U/L")
                InfoRow(label: "ALP", value: labData.alp, unit: "U/L")
                InfoRow(label: "LDH", value: labData.ldh, unit: "U/L")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Electrolyte & Glucose Section
    
    private var electrolyteGlucoseSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("電解質・血糖")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                InfoRow(label: "ナトリウム (Na)", value: labData.sodium, unit: "mEq/L")
                InfoRow(label: "カリウム (K)", value: labData.potassium, unit: "mEq/L")
                InfoRow(label: "クロール (Cl)", value: labData.chloride, unit: "mEq/L")
                InfoRow(label: "血糖 (Glu)", value: labData.glucose, unit: "mg/dL")
                InfoRow(label: "HbA1c", value: labData.hba1c, unit: "%")
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Helper
    
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
        LabDataDetailView(labData: {
            let context = PersistenceController.preview.container.viewContext
            let labData = LabData(context: context)
            labData.testDate = Date()
            labData.wbc = 6.5
            labData.rbc = 4.5
            labData.hb = 14.0
            return labData
        }())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
