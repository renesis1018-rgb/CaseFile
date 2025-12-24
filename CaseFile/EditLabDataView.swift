//
//  EditLabDataView.swift
//  CaseFile
//
//  Fixed: urea → un に変更

import SwiftUI

struct EditLabDataView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var labData: LabData
    
    // MARK: - 血球系
    @State private var wbc: String = ""
    @State private var rbc: String = ""
    @State private var hb: String = ""
    @State private var hematocrit: String = ""
    @State private var mcv: String = ""
    @State private var mch: String = ""
    @State private var mchc: String = ""
    @State private var platelet: String = ""
    
    // MARK: - 凝固系
    @State private var prothrombinTime: String = ""
    @State private var ptTime: String = ""
    @State private var ptControl: String = ""
    @State private var ptActivity: String = ""
    @State private var ptInr: String = ""
    @State private var aptt: String = ""
    
    // MARK: - 生化学系
    @State private var totalProtein: String = ""
    @State private var uricAcid: String = ""
    @State private var un: String = ""  // ✅ 修正: urea → un
    @State private var indirectBilirubin: String = ""
    @State private var creatinine: String = ""
    
    // MARK: - 肝機能系
    @State private var ast: String = ""
    @State private var alt: String = ""
    @State private var gammaGtp: String = ""
    @State private var totalBilirubin: String = ""
    @State private var directBilirubin: String = ""
    @State private var alp: String = ""
    @State private var ldh: String = ""
    
    // MARK: - 電解質・血糖系
    @State private var sodium: String = ""
    @State private var potassium: String = ""
    @State private var chloride: String = ""
    @State private var iron: String = ""
    @State private var totalCholesterol: String = ""
    @State private var triglyceride: String = ""
    @State private var glucose: String = ""
    @State private var hba1c: String = ""
    
    // MARK: - 感染症マーカー系
    @State private var hbsAntigenResult: String = ""
    @State private var hbsAntigenValue: String = ""
    @State private var hbsAntibodyResult: String = ""
    @State private var hbsAntibodyValue: String = ""
    @State private var bloodTypeAbo: String = ""
    @State private var bloodTypeRh: String = ""
    @State private var rprResult: String = ""
    @State private var syphilisTpResult: String = ""
    @State private var hcvAntibodyResult: String = ""
    @State private var hcvAntibodyIndex: String = ""
    @State private var hcvAntibodyUnit: String = ""
    @State private var hivResult: String = ""
    
    // MARK: - その他項目
    @State private var otherTests: String = ""
    
    // アラート制御
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // MARK: - 基本情報
                Section(header: Text("基本情報")) {
                    if let patientName = labData.patient?.name {
                        Text("患者名: \(patientName)")
                            .font(.headline)
                    }
                    if let testDate = labData.testDate {
                        Text("検査日: \(testDate, formatter: dateFormatter)")
                            .font(.subheadline)
                    }
                }
                
                // MARK: - 血球系
                Section(header: Text("血球系")) {
                    LabValueField(label: "白血球数(WBC)", value: $wbc, unit: "×10³/μL")
                    LabValueField(label: "赤血球数(RBC)", value: $rbc, unit: "×10⁴/μL")
                    LabValueField(label: "血色素量(Hb)", value: $hb, unit: "g/dL")
                    LabValueField(label: "ヘマトクリット(Ht)", value: $hematocrit, unit: "%")
                    LabValueField(label: "MCV", value: $mcv, unit: "fL")
                    LabValueField(label: "MCH", value: $mch, unit: "pg")
                    LabValueField(label: "MCHC", value: $mchc, unit: "%")
                    LabValueField(label: "血小板数", value: $platelet, unit: "×10⁴/μL")
                }
                
                // MARK: - 凝固系
                Section(header: Text("凝固系")) {
                    LabValueField(label: "プロトロンビン時間", value: $prothrombinTime, unit: "秒")
                    LabValueField(label: "PT時間", value: $ptTime, unit: "秒")
                    LabValueField(label: "対照", value: $ptControl, unit: "秒")
                    LabValueField(label: "PT活性値", value: $ptActivity, unit: "%")
                    LabValueField(label: "PT-INR", value: $ptInr, unit: "")
                    LabValueField(label: "APTT", value: $aptt, unit: "秒")
                }
                
                // MARK: - 生化学系
                Section(header: Text("生化学系")) {
                    LabValueField(label: "総蛋白(TP)", value: $totalProtein, unit: "g/dL")
                    LabValueField(label: "尿酸(UA)", value: $uricAcid, unit: "mg/dL")
                    LabValueField(label: "尿素窒素(UN)", value: $un, unit: "mg/dL")  // ✅ 修正
                    LabValueField(label: "I-BIL", value: $indirectBilirubin, unit: "mg/dL")
                    LabValueField(label: "クレアチニン(CREA)", value: $creatinine, unit: "mg/dL")
                }
                
                // MARK: - 肝機能系
                Section(header: Text("肝機能系")) {
                    LabValueField(label: "AST(GOT)", value: $ast, unit: "U/L")
                    LabValueField(label: "ALT(GPT)", value: $alt, unit: "U/L")
                    LabValueField(label: "γ-GT(γ-GTP)", value: $gammaGtp, unit: "U/L")
                    LabValueField(label: "総ビリルビン", value: $totalBilirubin, unit: "mg/dL")
                    LabValueField(label: "直接ビリルビン", value: $directBilirubin, unit: "mg/dL")
                    LabValueField(label: "ALP/IFCC", value: $alp, unit: "U/L")
                    LabValueField(label: "LD/IFCC", value: $ldh, unit: "U/L")
                }
                
                // MARK: - 電解質・血糖系
                Section(header: Text("電解質・血糖系")) {
                    LabValueField(label: "ナトリウム(Na)", value: $sodium, unit: "mEq/L")
                    LabValueField(label: "カリウム(K)", value: $potassium, unit: "mEq/L")
                    LabValueField(label: "クロール(Cl)", value: $chloride, unit: "mEq/L")
                    LabValueField(label: "鉄(Fe)", value: $iron, unit: "μg/dL")
                    LabValueField(label: "総コレステロール", value: $totalCholesterol, unit: "mg/dL")
                    LabValueField(label: "中性脂肪(TG)", value: $triglyceride, unit: "mg/dL")
                    LabValueField(label: "血糖(空腹時)", value: $glucose, unit: "mg/dL")
                    LabValueField(label: "HbA1c(NGSP)", value: $hba1c, unit: "%")
                }
                
                // MARK: - 感染症マーカー系
                Section(header: Text("感染症マーカー系")) {
                    LabValueField(label: "HBs抗原/CLIA 判定", value: $hbsAntigenResult, unit: "")
                    LabValueField(label: "HBs抗原/CLIA 定量値", value: $hbsAntigenValue, unit: "COI")
                    LabValueField(label: "HBs抗体/CLIA 判定", value: $hbsAntibodyResult, unit: "")
                    LabValueField(label: "HBs抗体/CLIA 定量値", value: $hbsAntibodyValue, unit: "mIU/mL")
                    LabValueField(label: "血液型 ABO式", value: $bloodTypeAbo, unit: "")
                    LabValueField(label: "血液型 Rh(D)式", value: $bloodTypeRh, unit: "")
                    LabValueField(label: "RPR法 定性", value: $rprResult, unit: "")
                    LabValueField(label: "梅毒TP抗体定性", value: $syphilisTpResult, unit: "")
                    LabValueField(label: "HCV抗体 3rd 判定", value: $hcvAntibodyResult, unit: "")
                    LabValueField(label: "HCV抗体 インデックス", value: $hcvAntibodyIndex, unit: "")
                    LabValueField(label: "HCV抗体 ユニット", value: $hcvAntibodyUnit, unit: "")
                    LabValueField(label: "HIV抗原・抗体同時定性", value: $hivResult, unit: "")
                }
                
                // MARK: - その他
                Section(header: Text("その他")) {
                    TextEditor(text: $otherTests)
                        .frame(height: 80)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .navigationTitle("血液検査データ編集")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveLabData()
                    }
                }
            }
            .alert(isPresented: $showAlert) {
                Alert(title: Text("保存完了"), message: Text(alertMessage), dismissButton: .default(Text("OK")) {
                    dismiss()
                })
            }
            .onAppear {
                loadLabData()
            }
        }
    }
    
    // MARK: - データ読み込み
    private func loadLabData() {
        // 血球系
        wbc = labData.wbc?.stringValue ?? ""
        rbc = labData.rbc?.stringValue ?? ""
        hb = labData.hb?.stringValue ?? ""
        hematocrit = labData.hematocrit?.stringValue ?? ""
        mcv = labData.mcv?.stringValue ?? ""
        mch = labData.mch?.stringValue ?? ""
        mchc = labData.mchc?.stringValue ?? ""
        platelet = labData.platelet?.stringValue ?? ""
        
        // 凝固系
        prothrombinTime = labData.prothrombinTime?.stringValue ?? ""
        ptTime = labData.ptTime?.stringValue ?? ""
        ptControl = labData.ptControl?.stringValue ?? ""
        ptActivity = labData.ptActivity?.stringValue ?? ""
        ptInr = labData.ptInr?.stringValue ?? ""
        aptt = labData.aptt?.stringValue ?? ""
        
        // 生化学系
        totalProtein = labData.totalProtein?.stringValue ?? ""
        uricAcid = labData.uricAcid?.stringValue ?? ""
        un = labData.un?.stringValue ?? ""  // ✅ 修正: urea → un
        indirectBilirubin = labData.indirectBilirubin?.stringValue ?? ""
        creatinine = labData.creatinine?.stringValue ?? ""
        
        // 肝機能系
        ast = labData.ast?.stringValue ?? ""
        alt = labData.alt?.stringValue ?? ""
        gammaGtp = labData.gammaGtp?.stringValue ?? ""
        totalBilirubin = labData.totalBilirubin?.stringValue ?? ""
        directBilirubin = labData.directBilirubin?.stringValue ?? ""
        alp = labData.alp?.stringValue ?? ""
        ldh = labData.ldh?.stringValue ?? ""
        
        // 電解質・血糖系
        sodium = labData.sodium?.stringValue ?? ""
        potassium = labData.potassium?.stringValue ?? ""
        chloride = labData.chloride?.stringValue ?? ""
        iron = labData.iron?.stringValue ?? ""
        totalCholesterol = labData.totalCholesterol?.stringValue ?? ""
        triglyceride = labData.triglyceride?.stringValue ?? ""
        glucose = labData.glucose?.stringValue ?? ""
        hba1c = labData.hba1c?.stringValue ?? ""
        
        // 感染症マーカー系
        hbsAntigenResult = labData.hbsAntigenResult ?? ""
        hbsAntigenValue = labData.hbsAntigenValue?.stringValue ?? ""
        hbsAntibodyResult = labData.hbsAntibodyResult ?? ""
        hbsAntibodyValue = labData.hbsAntibodyValue ?? ""
        bloodTypeAbo = labData.bloodTypeAbo ?? ""
        bloodTypeRh = labData.bloodTypeRh ?? ""
        rprResult = labData.rprResult ?? ""
        syphilisTpResult = labData.syphilisTpResult ?? ""
        hcvAntibodyResult = labData.hcvAntibodyResult ?? ""
        hcvAntibodyIndex = labData.hcvAntibodyIndex?.stringValue ?? ""
        hcvAntibodyUnit = labData.hcvAntibodyUnit ?? ""
        hivResult = labData.hivResult ?? ""
        
        // その他
        otherTests = labData.otherTests ?? ""
    }
    
    // MARK: - データ保存
    private func saveLabData() {
        // 血球系
        labData.wbc = wbc.isEmpty ? nil : NSNumber(value: Double(wbc) ?? 0)
        labData.rbc = rbc.isEmpty ? nil : NSNumber(value: Double(rbc) ?? 0)
        labData.hb = hb.isEmpty ? nil : NSNumber(value: Double(hb) ?? 0)
        labData.hematocrit = hematocrit.isEmpty ? nil : NSNumber(value: Double(hematocrit) ?? 0)
        labData.mcv = mcv.isEmpty ? nil : NSNumber(value: Double(mcv) ?? 0)
        labData.mch = mch.isEmpty ? nil : NSNumber(value: Double(mch) ?? 0)
        labData.mchc = mchc.isEmpty ? nil : NSNumber(value: Double(mchc) ?? 0)
        labData.platelet = platelet.isEmpty ? nil : NSNumber(value: Double(platelet) ?? 0)
        
        // 凝固系
        labData.prothrombinTime = prothrombinTime.isEmpty ? nil : NSNumber(value: Double(prothrombinTime) ?? 0)
        labData.ptTime = ptTime.isEmpty ? nil : NSNumber(value: Double(ptTime) ?? 0)
        labData.ptControl = ptControl.isEmpty ? nil : NSNumber(value: Double(ptControl) ?? 0)
        labData.ptActivity = ptActivity.isEmpty ? nil : NSNumber(value: Double(ptActivity) ?? 0)
        labData.ptInr = ptInr.isEmpty ? nil : NSNumber(value: Double(ptInr) ?? 0)
        labData.aptt = aptt.isEmpty ? nil : NSNumber(value: Double(aptt) ?? 0)
        
        // 生化学系
        labData.totalProtein = totalProtein.isEmpty ? nil : NSNumber(value: Double(totalProtein) ?? 0)
        labData.uricAcid = uricAcid.isEmpty ? nil : NSNumber(value: Double(uricAcid) ?? 0)
        labData.un = un.isEmpty ? nil : NSNumber(value: Double(un) ?? 0)  // ✅ 修正: urea → un
        labData.indirectBilirubin = indirectBilirubin.isEmpty ? nil : NSNumber(value: Double(indirectBilirubin) ?? 0)
        labData.creatinine = creatinine.isEmpty ? nil : NSNumber(value: Double(creatinine) ?? 0)
        
        // 肝機能系
        labData.ast = ast.isEmpty ? nil : NSNumber(value: Double(ast) ?? 0)
        labData.alt = alt.isEmpty ? nil : NSNumber(value: Double(alt) ?? 0)
        labData.gammaGtp = gammaGtp.isEmpty ? nil : NSNumber(value: Double(gammaGtp) ?? 0)
        labData.totalBilirubin = totalBilirubin.isEmpty ? nil : NSNumber(value: Double(totalBilirubin) ?? 0)
        labData.directBilirubin = directBilirubin.isEmpty ? nil : NSNumber(value: Double(directBilirubin) ?? 0)
        labData.alp = alp.isEmpty ? nil : NSNumber(value: Double(alp) ?? 0)
        labData.ldh = ldh.isEmpty ? nil : NSNumber(value: Double(ldh) ?? 0)
        
        // 電解質・血糖系
        labData.sodium = sodium.isEmpty ? nil : NSNumber(value: Double(sodium) ?? 0)
        labData.potassium = potassium.isEmpty ? nil : NSNumber(value: Double(potassium) ?? 0)
        labData.chloride = chloride.isEmpty ? nil : NSNumber(value: Double(chloride) ?? 0)
        labData.iron = iron.isEmpty ? nil : NSNumber(value: Double(iron) ?? 0)
        labData.totalCholesterol = totalCholesterol.isEmpty ? nil : NSNumber(value: Double(totalCholesterol) ?? 0)
        labData.triglyceride = triglyceride.isEmpty ? nil : NSNumber(value: Double(triglyceride) ?? 0)
        labData.glucose = glucose.isEmpty ? nil : NSNumber(value: Double(glucose) ?? 0)
        labData.hba1c = hba1c.isEmpty ? nil : NSNumber(value: Double(hba1c) ?? 0)
        
        // 感染症マーカー系
        labData.hbsAntigenResult = hbsAntigenResult.isEmpty ? nil : hbsAntigenResult
        labData.hbsAntigenValue = hbsAntigenValue.isEmpty ? nil : NSNumber(value: Double(hbsAntigenValue) ?? 0)
        labData.hbsAntibodyResult = hbsAntibodyResult.isEmpty ? nil : hbsAntibodyResult
        labData.hbsAntibodyValue = hbsAntibodyValue.isEmpty ? nil : hbsAntibodyValue
        labData.bloodTypeAbo = bloodTypeAbo.isEmpty ? nil : bloodTypeAbo
        labData.bloodTypeRh = bloodTypeRh.isEmpty ? nil : bloodTypeRh
        labData.rprResult = rprResult.isEmpty ? nil : rprResult
        labData.syphilisTpResult = syphilisTpResult.isEmpty ? nil : syphilisTpResult
        labData.hcvAntibodyResult = hcvAntibodyResult.isEmpty ? nil : hcvAntibodyResult
        labData.hcvAntibodyIndex = hcvAntibodyIndex.isEmpty ? nil : NSNumber(value: Double(hcvAntibodyIndex) ?? 0)
        labData.hcvAntibodyUnit = hcvAntibodyUnit.isEmpty ? nil : hcvAntibodyUnit
        labData.hivResult = hivResult.isEmpty ? nil : hivResult
        
        // その他
        labData.otherTests = otherTests.isEmpty ? nil : otherTests
        
        // 保存実行
        do {
            try viewContext.save()
            alertMessage = "血液検査データを保存しました"
            showAlert = true
        } catch {
            alertMessage = "保存に失敗しました: \(error.localizedDescription)"
            showAlert = true
        }
    }
}

// MARK: - Date Formatter
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter
}()

struct EditLabDataView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let labData = LabData(context: context)
        return EditLabDataView(labData: labData)
            .environment(\.managedObjectContext, context)
    }
}
