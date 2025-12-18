//
//  AddLabDataView.swift
//  CaseFile
//
//  血液検査データ入力画面（47項目完全対応版）
//

import SwiftUI
import CoreData

struct AddLabDataView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var patient: Patient
    let context: NSManagedObjectContext
    
    // 関連する手術（オプション）
    var surgery: Surgery? = nil
    
    // MARK: - 基本情報
    @State private var testDate = Date()
    @State private var otherTests = ""
    
    // MARK: - 血球系 (8項目)
    @State private var wbc = ""
    @State private var rbc = ""
    @State private var hb = ""
    @State private var hematocrit = ""
    @State private var mcv = ""
    @State private var mch = ""
    @State private var mchc = ""
    @State private var platelet = ""
    
    // MARK: - 凝固系 (6項目)
    @State private var prothrombinTime = ""
    @State private var ptTime = ""
    @State private var ptControl = ""
    @State private var ptActivity = ""
    @State private var ptInr = ""
    @State private var aptt = ""
    
    // MARK: - 生化学系 (10項目)
    @State private var totalProtein = ""
    @State private var uricAcid = ""
    @State private var urea = ""
    @State private var indirectBilirubin = ""
    @State private var creatinine = ""
    @State private var iron = ""
    @State private var totalCholesterol = ""
    @State private var triglyceride = ""
    @State private var totalBilirubin = ""
    @State private var directBilirubin = ""
    
    // MARK: - 肝機能 (5項目)
    @State private var ast = ""
    @State private var alt = ""
    @State private var gammaGtp = ""
    @State private var glucose = ""
    @State private var alp = ""
    @State private var ldh = ""
    
    // MARK: - 感染症マーカー (12項目)
    @State private var hbsAntigenResult = ""
    @State private var hbsAntigenValue = ""
    @State private var hbsAntibodyResult = ""
    @State private var hbsAntibodyValue = ""
    @State private var bloodTypeAbo = ""
    @State private var bloodTypeRh = ""
    @State private var rprResult = ""
    @State private var syphilisTpAntibody = ""
    @State private var hba1c = ""
    @State private var hcvAntibodyResult = ""
    @State private var hcvIndex = ""
    @State private var hcvUnit = ""
    @State private var hivTest = ""
    
    // MARK: - 電解質 (4項目)
    @State private var sodium = ""
    @State private var potassium = ""
    @State private var chloride = ""
    
    // MARK: - エラー表示
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // MARK: - 基本情報
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("基本情報")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            DatePicker("検査日", selection: $testDate, displayedComponents: .date)
                            
                            if let surgery = surgery {
                                HStack {
                                    Text("関連手術")
                                        .frame(width: 100, alignment: .leading)
                                    Text(surgery.surgeryType ?? "不明")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding()
                    }
                    .padding()
                    
                    // MARK: - 血球系
                    bloodCellSection
                    
                    // MARK: - 凝固系
                    coagulationSection
                    
                    // MARK: - 生化学系
                    biochemistrySection
                    
                    // MARK: - 肝機能
                    liverFunctionSection
                    
                    // MARK: - 感染症マーカー
                    infectiousMarkerSection
                    
                    // MARK: - 電解質
                    electrolyteSection
                    
                    // MARK: - その他の検査
                    otherTestsSection
                }
            }
            .navigationTitle("血液検査登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveLabData() }
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(minWidth: 900, idealWidth: 1000, minHeight: 800)
    }
    
    // MARK: - 血球系セクション
    private var bloodCellSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("血球系")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    LabValueField(label: "白血球数 (WBC)", value: $wbc, unit: "×10³/μL")
                    LabValueField(label: "赤血球数 (RBC)", value: $rbc, unit: "×10⁴/μL")
                }
                
                HStack {
                    LabValueField(label: "血色素量 (Hb)", value: $hb, unit: "g/dL")
                    LabValueField(label: "ヘマトクリット (Ht)", value: $hematocrit, unit: "%")
                }
                
                HStack {
                    LabValueField(label: "MCV", value: $mcv, unit: "fL")
                    LabValueField(label: "MCH", value: $mch, unit: "pg")
                }
                
                HStack {
                    LabValueField(label: "MCHC", value: $mchc, unit: "%")
                    LabValueField(label: "血小板数", value: $platelet, unit: "×10⁴/μL")
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 凝固系セクション
    private var coagulationSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("凝固系")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    LabValueField(label: "プロトロンビン時間", value: $prothrombinTime, unit: "秒")
                    LabValueField(label: "PT時間", value: $ptTime, unit: "秒")
                }
                
                HStack {
                    LabValueField(label: "対照", value: $ptControl, unit: "秒")
                    LabValueField(label: "PT活性値", value: $ptActivity, unit: "%")
                }
                
                HStack {
                    LabValueField(label: "PT-INR", value: $ptInr, unit: "")
                    LabValueField(label: "APTT", value: $aptt, unit: "秒")
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 生化学系セクション
    private var biochemistrySection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("生化学系")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    LabValueField(label: "総蛋白 (TP)", value: $totalProtein, unit: "g/dL")
                    LabValueField(label: "尿酸 (UA)", value: $uricAcid, unit: "mg/dL")
                }
                
                HStack {
                    LabValueField(label: "尿素窒素 (UN)", value: $urea, unit: "mg/dL")
                    LabValueField(label: "I-BIL", value: $indirectBilirubin, unit: "mg/dL")
                }
                
                HStack {
                    LabValueField(label: "クレアチニン (CREA)", value: $creatinine, unit: "mg/dL")
                    LabValueField(label: "鉄 (Fe)", value: $iron, unit: "μg/dL")
                }
                
                HStack {
                    LabValueField(label: "総コレステロール", value: $totalCholesterol, unit: "mg/dL")
                    LabValueField(label: "中性脂肪 (TG)", value: $triglyceride, unit: "mg/dL")
                }
                
                HStack {
                    LabValueField(label: "総ビリルビン", value: $totalBilirubin, unit: "mg/dL")
                    LabValueField(label: "直接ビリルビン", value: $directBilirubin, unit: "mg/dL")
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 肝機能セクション
    private var liverFunctionSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("肝機能")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    LabValueField(label: "AST (GOT)", value: $ast, unit: "U/L")
                    LabValueField(label: "ALT (GPT)", value: $alt, unit: "U/L")
                }
                
                HStack {
                    LabValueField(label: "γ-GT (γ-GTP)", value: $gammaGtp, unit: "U/L")
                    LabValueField(label: "血糖 (空腹時)", value: $glucose, unit: "mg/dL")
                }
                
                HStack {
                    LabValueField(label: "ALP/IFCC", value: $alp, unit: "U/L")
                    LabValueField(label: "LD/IFCC", value: $ldh, unit: "U/L")
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 感染症マーカーセクション
    private var infectiousMarkerSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("感染症マーカー")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                // HBs抗原
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HBs抗原/CLIA 判定")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("陰性/陽性", text: $hbsAntigenResult)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                    
                    LabValueField(label: "定量値", value: $hbsAntigenValue, unit: "")
                }
                
                // HBs抗体
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HBs抗体/CLIA 判定")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("陰性/陽性", text: $hbsAntibodyResult)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                    
                    LabValueField(label: "定量値", value: $hbsAntibodyValue, unit: "")
                }
                
                // 血液型
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("血液型 ABO式")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("A/B/O/AB", text: $bloodTypeAbo)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("血液型 Rh(D)式")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("陽性/陰性", text: $bloodTypeRh)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // 梅毒
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("RPR法 定性")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("陰性/陽性", text: $rprResult)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("梅毒TP抗体定性")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("陰性/陽性", text: $syphilisTpAntibody)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                }
                
                // HbA1c
                HStack {
                    LabValueField(label: "HbA1c (NGSP)", value: $hba1c, unit: "%")
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
                
                // HCV抗体
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HCV抗体 3rd 判定")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("陰性/陽性", text: $hcvAntibodyResult)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                    
                    LabValueField(label: "インデックス", value: $hcvIndex, unit: "")
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HCV抗体 3rd ユニット")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("", text: $hcvUnit)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("HIV抗原・抗体同時定性")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("陰性/陽性", text: $hivTest)
                            .textFieldStyle(.roundedBorder)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 電解質セクション
    private var electrolyteSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("電解質")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    LabValueField(label: "ナトリウム (Na)", value: $sodium, unit: "mEq/L")
                    LabValueField(label: "カリウム (K)", value: $potassium, unit: "mEq/L")
                }
                
                HStack {
                    LabValueField(label: "クロール (Cl)", value: $chloride, unit: "mEq/L")
                    Spacer()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - その他の検査セクション
    private var otherTestsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("その他の検査・備考")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                TextEditor(text: $otherTests)
                    .frame(height: 100)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 保存処理
    private func saveLabData() {
        let newLabData = LabData(context: context)
        newLabData.id = UUID()
        newLabData.patient = patient
        newLabData.surgery = surgery
        newLabData.testDate = testDate
        newLabData.otherTests = otherTests
        
        // 血球系
        if !wbc.isEmpty, let value = Double(wbc) {
            newLabData.wbc = NSNumber(value: value)
        }
        if !rbc.isEmpty, let value = Double(rbc) {
            newLabData.rbc = NSNumber(value: value)
        }
        if !hb.isEmpty, let value = Double(hb) {
            newLabData.hb = NSNumber(value: value)
        }
        if !hematocrit.isEmpty, let value = Double(hematocrit) {
            newLabData.hematocrit = NSNumber(value: value)
        }
        if !mcv.isEmpty, let value = Double(mcv) {
            newLabData.mcv = NSNumber(value: value)
        }
        if !mch.isEmpty, let value = Double(mch) {
            newLabData.mch = NSNumber(value: value)
        }
        if !mchc.isEmpty, let value = Double(mchc) {
            newLabData.mchc = NSNumber(value: value)
        }
        if !platelet.isEmpty, let value = Double(platelet) {
            newLabData.platelet = NSNumber(value: value)
        }
        
        // 凝固系
        if !prothrombinTime.isEmpty, let value = Double(prothrombinTime) {
            newLabData.prothrombinTime = NSNumber(value: value)
        }
        if !ptTime.isEmpty, let value = Double(ptTime) {
            newLabData.ptTime = NSNumber(value: value)
        }
        if !ptControl.isEmpty, let value = Double(ptControl) {
            newLabData.ptControl = NSNumber(value: value)
        }
        if !ptActivity.isEmpty, let value = Double(ptActivity) {
            newLabData.ptActivity = NSNumber(value: value)
        }
        if !ptInr.isEmpty, let value = Double(ptInr) {
            newLabData.ptInr = NSNumber(value: value)
        }
        if !aptt.isEmpty, let value = Double(aptt) {
            newLabData.aptt = NSNumber(value: value)
        }
        
        // 生化学系
        if !totalProtein.isEmpty, let value = Double(totalProtein) {
            newLabData.totalProtein = NSNumber(value: value)
        }
        if !uricAcid.isEmpty, let value = Double(uricAcid) {
            newLabData.uricAcid = NSNumber(value: value)
        }
        if !urea.isEmpty, let value = Double(urea) {
            newLabData.urea = NSNumber(value: value)
        }
        if !indirectBilirubin.isEmpty, let value = Double(indirectBilirubin) {
            newLabData.indirectBilirubin = NSNumber(value: value)
        }
        if !creatinine.isEmpty, let value = Double(creatinine) {
            newLabData.creatinine = NSNumber(value: value)
        }
        if !iron.isEmpty, let value = Double(iron) {
            newLabData.iron = NSNumber(value: value)
        }
        if !totalCholesterol.isEmpty, let value = Double(totalCholesterol) {
            newLabData.totalCholesterol = NSNumber(value: value)
        }
        if !triglyceride.isEmpty, let value = Double(triglyceride) {
            newLabData.triglyceride = NSNumber(value: value)
        }
        if !totalBilirubin.isEmpty, let value = Double(totalBilirubin) {
            newLabData.totalBilirubin = NSNumber(value: value)
        }
        if !directBilirubin.isEmpty, let value = Double(directBilirubin) {
            newLabData.directBilirubin = NSNumber(value: value)
        }
        
        // 肝機能
        if !ast.isEmpty, let value = Double(ast) {
            newLabData.ast = NSNumber(value: value)
        }
        if !alt.isEmpty, let value = Double(alt) {
            newLabData.alt = NSNumber(value: value)
        }
        if !gammaGtp.isEmpty, let value = Double(gammaGtp) {
            newLabData.gammaGtp = NSNumber(value: value)
        }
        if !glucose.isEmpty, let value = Double(glucose) {
            newLabData.glucose = NSNumber(value: value)
        }
        if !alp.isEmpty, let value = Double(alp) {
            newLabData.alp = NSNumber(value: value)
        }
        if !ldh.isEmpty, let value = Double(ldh) {
            newLabData.ldh = NSNumber(value: value)
        }
        
        // 感染症マーカー
        if !hbsAntigenResult.isEmpty {
            newLabData.hbsAntigenResult = hbsAntigenResult
        }
        if !hbsAntigenValue.isEmpty, let value = Double(hbsAntigenValue) {
            newLabData.hbsAntigenValue = NSNumber(value: value)
        }
        if !hbsAntibodyResult.isEmpty {
            newLabData.hbsAntibodyResult = hbsAntibodyResult
        }
        if !hbsAntibodyValue.isEmpty {
            newLabData.hbsAntibodyValue = hbsAntibodyValue
        }
        if !bloodTypeAbo.isEmpty {
            newLabData.bloodTypeAbo = bloodTypeAbo
        }
        if !bloodTypeRh.isEmpty {
            newLabData.bloodTypeRh = bloodTypeRh
        }
        if !rprResult.isEmpty {
            newLabData.rprResult = rprResult
        }
        if !syphilisTpAntibody.isEmpty {
            newLabData.syphilisTpResult = syphilisTpAntibody
        }
        if !hba1c.isEmpty, let value = Double(hba1c) {
            newLabData.hba1c = NSNumber(value: value)
        }
        if !hcvAntibodyResult.isEmpty {
            newLabData.hcvAntibodyResult = hcvAntibodyResult
        }
        if !hcvIndex.isEmpty, let value = Double(hcvIndex) {
            newLabData.hcvAntibodyIndex = NSNumber(value: value)
        }
        if !hcvUnit.isEmpty {
            newLabData.hcvAntibodyUnit = hcvUnit
        }
        if !hivTest.isEmpty {
            newLabData.hivResult = hivTest
        }
        
        // 電解質
        if !sodium.isEmpty, let value = Double(sodium) {
            newLabData.sodium = NSNumber(value: value)
        }
        if !potassium.isEmpty, let value = Double(potassium) {
            newLabData.potassium = NSNumber(value: value)
        }
        if !chloride.isEmpty, let value = Double(chloride) {
            newLabData.chloride = NSNumber(value: value)
        }
        
        // Core Data保存
        do {
            try context.save()
            print("✅ 血液検査データ保存成功（47項目）")
            dismiss()
        } catch let error as NSError {
            print("❌ 血液検査データ保存エラー: \(error)")
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            showError = true
        }
    }
}

// MARK: - 血液検査値入力フィールド（再利用可能コンポーネント）
struct LabValueField: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 4) {
                TextField("", text: $value)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Preview
#Preview {
    let context = PersistenceController.preview.container.viewContext
    let patient = Patient(context: context)
    patient.id = UUID()
    patient.patientId = "TEST001"
    patient.name = "テスト患者"
    patient.registeredDate = Date()
    
    return AddLabDataView(patient: patient, context: context)
}
