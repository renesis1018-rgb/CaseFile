//
//  LabDataDetailView.swift
//  CaseFile
//
//  血液検査詳細画面（47項目完全対応版・修正版）
//

import SwiftUI
import CoreData

struct LabDataDetailView: View {
    @ObservedObject var labData: LabData
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showEditLabData = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 基本情報
                basicInfoSection
                
                Divider()
                
                // 血球系
                bloodCellSection
                
                Divider()
                
                // 凝固系
                coagulationSection
                
                Divider()
                
                // 生化学系
                biochemistrySection
                
                Divider()
                
                // 肝機能
                liverFunctionSection
                
                Divider()
                
                // 感染症マーカー
                infectiousMarkerSection
                
                Divider()
                
                // 電解質
                electrolyteSection
                
                Divider()
                
                // その他
                if let otherTests = labData.otherTests, !otherTests.isEmpty {
                    otherTestsSection
                }
            }
            .padding()
        }
        .frame(minWidth: 900, idealWidth: 1000, minHeight: 700)  // ✅ ウィンドウサイズ設定
        .navigationTitle("血液検査結果")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showEditLabData = true }) {
                    Label("編集", systemImage: "pencil")
                }
            }
        }
        .sheet(isPresented: $showEditLabData) {
            EditLabDataView(labData: labData)
        }
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("検査情報")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let date = labData.testDate {
                    LabDataInfoRow(label: "検査日", value: formatDate(date))
                }
                if let patient = labData.patient {
                    LabDataInfoRow(label: "患者ID", value: patient.patientId ?? "不明")
                    LabDataInfoRow(label: "患者名", value: patient.name ?? "不明")
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
                if let value = labData.wbc {
                    LabDataInfoRow(label: "白血球数 (WBC)", value: value, unit: "×10³/μL")
                }
                if let value = labData.rbc {
                    LabDataInfoRow(label: "赤血球数 (RBC)", value: value, unit: "×10⁴/μL")
                }
                if let value = labData.hb {
                    LabDataInfoRow(label: "血色素量 (Hb)", value: value, unit: "g/dL")
                }
                if let value = labData.hematocrit {
                    LabDataInfoRow(label: "ヘマトクリット (Ht)", value: value, unit: "%")
                }
                if let value = labData.mcv {
                    LabDataInfoRow(label: "MCV", value: value, unit: "fL")
                }
                if let value = labData.mch {
                    LabDataInfoRow(label: "MCH", value: value, unit: "pg")
                }
                if let value = labData.mchc {
                    LabDataInfoRow(label: "MCHC", value: value, unit: "%")
                }
                if let value = labData.platelet {
                    LabDataInfoRow(label: "血小板数", value: value, unit: "×10⁴/μL")
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Coagulation Section
    
    private var coagulationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("凝固系")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let value = labData.prothrombinTime {
                    LabDataInfoRow(label: "プロトロンビン時間", value: value, unit: "秒")
                }
                if let value = labData.ptTime {
                    LabDataInfoRow(label: "PT時間", value: value, unit: "秒")
                }
                if let value = labData.ptControl {
                    LabDataInfoRow(label: "対照", value: value, unit: "秒")
                }
                if let value = labData.ptActivity {
                    LabDataInfoRow(label: "PT活性値", value: value, unit: "%")
                }
                if let value = labData.ptInr {
                    LabDataInfoRow(label: "PT-INR", value: value, unit: "")
                }
                if let value = labData.aptt {
                    LabDataInfoRow(label: "APTT", value: value, unit: "秒")
                }
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
                if let value = labData.totalProtein {
                    LabDataInfoRow(label: "総蛋白 (TP)", value: value, unit: "g/dL")
                }
                if let value = labData.uricAcid {
                    LabDataInfoRow(label: "尿酸 (UA)", value: value, unit: "mg/dL")
                }
                if let value = labData.un {
                    LabDataInfoRow(label: "尿素窒素 (UN)", value: value, unit: "mg/dL")
                }
                if let value = labData.indirectBilirubin {
                    LabDataInfoRow(label: "I-BIL", value: value, unit: "mg/dL")
                }
                if let value = labData.creatinine {
                    LabDataInfoRow(label: "クレアチニン (CREA)", value: value, unit: "mg/dL")
                }
                if let value = labData.iron {
                    LabDataInfoRow(label: "鉄 (Fe)", value: value, unit: "μg/dL")
                }
                if let value = labData.totalCholesterol {
                    LabDataInfoRow(label: "総コレステロール", value: value, unit: "mg/dL")
                }
                if let value = labData.triglyceride {
                    LabDataInfoRow(label: "中性脂肪 (TG)", value: value, unit: "mg/dL")
                }
                if let value = labData.totalBilirubin {
                    LabDataInfoRow(label: "総ビリルビン", value: value, unit: "mg/dL")
                }
                if let value = labData.directBilirubin {
                    LabDataInfoRow(label: "直接ビリルビン", value: value, unit: "mg/dL")
                }
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
                if let value = labData.ast {
                    LabDataInfoRow(label: "AST (GOT)", value: value, unit: "U/L")
                }
                if let value = labData.alt {
                    LabDataInfoRow(label: "ALT (GPT)", value: value, unit: "U/L")
                }
                if let value = labData.gammaGtp {
                    LabDataInfoRow(label: "γ-GT (γ-GTP)", value: value, unit: "U/L")
                }
                if let value = labData.glucose {
                    LabDataInfoRow(label: "血糖 (空腹時)", value: value, unit: "mg/dL")
                }
                if let value = labData.alp {
                    LabDataInfoRow(label: "ALP/IFCC", value: value, unit: "U/L")
                }
                if let value = labData.ldh {
                    LabDataInfoRow(label: "LD/IFCC", value: value, unit: "U/L")
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Infectious Marker Section
    
    private var infectiousMarkerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("感染症マーカー")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                // HBs抗原
                if let result = labData.hbsAntigenResult, !result.isEmpty {
                    LabDataInfoRow(label: "HBs抗原/CLIA 判定", value: result)
                }
                if let value = labData.hbsAntigenValue {
                    LabDataInfoRow(label: "HBs抗原/CLIA 定量値", value: value, unit: "")
                }
                
                // HBs抗体
                if let result = labData.hbsAntibodyResult, !result.isEmpty {
                    LabDataInfoRow(label: "HBs抗体/CLIA 判定", value: result)
                }
                if let value = labData.hbsAntibodyValue, !value.isEmpty {
                    LabDataInfoRow(label: "HBs抗体/CLIA 定量値", value: value, unit: "")
                }
                
                // 血液型
                if let abo = labData.bloodTypeAbo, !abo.isEmpty {
                    LabDataInfoRow(label: "血液型 ABO式", value: abo)
                }
                if let rh = labData.bloodTypeRh, !rh.isEmpty {
                    LabDataInfoRow(label: "血液型 Rh(D)式", value: rh)
                }
                
                // 梅毒
                if let rpr = labData.rprResult, !rpr.isEmpty {
                    LabDataInfoRow(label: "RPR法 定性", value: rpr)
                }
                if let tp = labData.syphilisTpResult, !tp.isEmpty {
                    LabDataInfoRow(label: "梅毒TP抗体定性", value: tp)
                }
                
                // HbA1c
                if let value = labData.hba1c {
                    LabDataInfoRow(label: "HbA1c (NGSP)", value: value, unit: "%")
                }
                
                // HCV抗体
                if let result = labData.hcvAntibodyResult, !result.isEmpty {
                    LabDataInfoRow(label: "HCV抗体 3rd 判定", value: result)
                }
                if let index = labData.hcvAntibodyIndex {
                    LabDataInfoRow(label: "HCV抗体 3rd インデックス", value: index, unit: "")
                }
                if let unit = labData.hcvAntibodyUnit, !unit.isEmpty {
                    LabDataInfoRow(label: "HCV抗体 3rd ユニット", value: unit)
                }
                
                // HIV
                if let hiv = labData.hivResult, !hiv.isEmpty {
                    LabDataInfoRow(label: "HIV抗原・抗体同時定性", value: hiv)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Electrolyte Section
    
    private var electrolyteSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("電解質")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let value = labData.sodium {
                    LabDataInfoRow(label: "ナトリウム (Na)", value: value, unit: "mEq/L")
                }
                if let value = labData.potassium {
                    LabDataInfoRow(label: "カリウム (K)", value: value, unit: "mEq/L")
                }
                if let value = labData.chloride {
                    LabDataInfoRow(label: "クロール (Cl)", value: value, unit: "mEq/L")
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Other Tests Section
    
    private var otherTestsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("その他の検査・備考")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(labData.otherTests ?? "")
                    .font(.system(size: 13))
                    .textSelection(.enabled)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
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

// MARK: - LabDataInfoRow (血液検査専用)

struct LabDataInfoRow: View {
    let label: String
    let value: String
    let unit: String?
    
    init(label: String, value: String, unit: String? = nil) {
        self.label = label
        self.value = value
        self.unit = unit
    }
    
    init(label: String, value: NSNumber, unit: String? = nil) {
        self.label = label
        self.value = "\(value.doubleValue)"
        self.unit = unit
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 200, alignment: .leading)
            
            Text(value)
                .font(.system(size: 13))
                .frame(alignment: .leading)
            
            if let unit = unit, !unit.isEmpty {
                Text(unit)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
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
