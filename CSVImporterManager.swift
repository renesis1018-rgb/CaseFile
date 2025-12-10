import Foundation
import CoreData
import Combine

// MARK: - Import Step
enum ImportStep: Int, CaseIterable {
    case patient = 1
    case surgery = 2
    case labData = 3
    case followUp = 4
    
    var title: String {
        switch self {
        case .patient: return "患者基本情報"
        case .surgery: return "手術情報"
        case .labData: return "血液検査"
        case .followUp: return "経過情報"
        }
    }
}

// MARK: - Import Result
struct ImportResult {
    var success: Int = 0
    var failed: Int = 0
    var errors: [String] = []
}

// MARK: - CSV Importer Manager
class CSVImporterManager: ObservableObject {
    @Published var isImporting = false
    @Published var importProgress: Double = 0
    @Published var importResult: ImportResult?
    @Published var currentStep: String = ""
    
    // MARK: - Patient Import
    func importPatientData(from fileURL: URL, context: NSManagedObjectContext) throws {
        let data = try String(contentsOf: fileURL, encoding: .utf8)
        let rows = data.components(separatedBy: .newlines).filter { !$0.isEmpty }
        
        guard rows.count > 1 else { return }
        let headers = parseCSVLine(rows[0])
        
        for i in 1..<rows.count {
            let values = parseCSVLine(rows[i])
            guard values.count == headers.count else { continue }
            
            var dataDict: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                dataDict[header] = values[index]
            }
            
            try importPatient(from: dataDict, context: context)
        }
        
        try context.save()
    }
    
    private func importPatient(from data: [String: String], context: NSManagedObjectContext) throws {
        let patient = Patient(context: context)
        patient.id = UUID()
        patient.patientId = data["患者ID"] ?? UUID().uuidString
        patient.name = data["氏名"] ?? ""
        patient.age = NSNumber(value: Int16(data["年齢"] ?? "0") ?? 0)
        patient.gender = data["性別"]
        patient.contactInfo = data["連絡先"]
        patient.notes = data["備考"]
        patient.registeredDate = parseDate(data["登録日"]) ?? Date()
        
        // Surgery data (if exists in CSV)
        if let surgeryDate = parseDate(data["手術日"]) {
            let surgery = Surgery(context: context)
            surgery.id = UUID()
            surgery.surgeryDate = surgeryDate
            surgery.surgeryCategory = data["手術カテゴリ"]
            surgery.surgeryType = data["手術種別"]
            surgery.patient = patient
            
            // Height and Weight (stored in Surgery entity)
            if let height = parseDouble(data["身長(cm)"]) {
                surgery.height = NSNumber(value: height / 100.0)  // cm → m
            }
            if let bw = parseDouble(data["体重(kg)"]) {
                surgery.bodyWeight = NSNumber(value: bw)
            }
            if let height = surgery.height?.doubleValue, let bw = surgery.bodyWeight?.doubleValue, height > 0, bw > 0 {
                surgery.bmi = NSNumber(value: bw / (height * height))
            }
            
            surgery.smokingHistory = data["喫煙歴"]
            surgery.breastfeedingHistory = data["授乳歴"]
            
            // Pre-operative measurements (common for breast augmentation)
            if let value = parseDouble(data["術前NAC-IMF右(cm)"]) {
                surgery.nacImfRight = NSNumber(value: value)
            }
            if let value = parseDouble(data["術前NAC-IMF左(cm)"]) {
                surgery.nacImfLeft = NSNumber(value: value)
            }
            if let value = parseDouble(data["皮膚厚右(mm)"]) {
                surgery.skinThicknessRight = NSNumber(value: value)
            }
            if let value = parseDouble(data["皮膚厚左(mm)"]) {
                surgery.skinThicknessLeft = NSNumber(value: value)
            }
            
            // Fat injection specific
            if let value = parseDouble(data["注入量右(cc)"]) {
                surgery.injectionVolumeR = NSNumber(value: value)
            }
            if let value = parseDouble(data["注入量左(cc)"]) {
                surgery.injectionVolumeL = NSNumber(value: value)
            }
            surgery.donorSite = data["採取部位"]
            
            if let value = parseDouble(data["皮下右(cc)"]) {
                surgery.subcutaneousRight = NSNumber(value: value)
            }
            if let value = parseDouble(data["皮下左(cc)"]) {
                surgery.subcutaneousLeft = NSNumber(value: value)
            }
            if let value = parseDouble(data["乳腺下右(cc)"]) {
                surgery.subglandularRight = NSNumber(value: value)
            }
            if let value = parseDouble(data["乳腺下左(cc)"]) {
                surgery.subglandularLeft = NSNumber(value: value)
            }
            if let value = parseDouble(data["筋肉内右(cc)"]) {
                surgery.submuscularRight = NSNumber(value: value)
            }
            if let value = parseDouble(data["筋肉内左(cc)"]) {
                surgery.submuscularLeft = NSNumber(value: value)
            }
            
            // Silicone breast augmentation specific
            if let sizeR = parseDouble(data["インプラントサイズ右(cc)"]) {
                surgery.implantSizeR = NSNumber(value: sizeR)
            }
            if let sizeL = parseDouble(data["インプラントサイズ左(cc)"]) {
                surgery.implantSizeL = NSNumber(value: sizeL)
            }
            surgery.implantManufacturer = data["インプラント製造元"]
            surgery.implantShape = data["インプラント形状"]
            surgery.insertionPlane = data["挿入位置"]
            surgery.incisionSite = data["切開位置"]
            
            // Liposuction specific
            if let volR = parseDouble(data["吸引量右(cc)"]) {
                surgery.liposuctionVolume = NSNumber(value: volR)
            }
           
            surgery.liposuctionDevice = data["吸引機器"]
            surgery.anesthesiaMethod = data["麻酔方法"]
        }
        
        // Lab data (if exists in CSV)
        if let testDate = parseDate(data["検査日"]) {
            let labData = LabData(context: context)
            labData.id = UUID()
            labData.testDate = testDate
            labData.patient = patient
            
            if let value = parseDouble(data["白血球数(WBC)"]) { labData.wbc = NSNumber(value: value) }
            if let value = parseDouble(data["赤血球数(RBC)"]) { labData.rbc = NSNumber(value: value) }
            if let value = parseDouble(data["血色素量(Hb)"]) { labData.hb = NSNumber(value: value) }
            if let value = parseDouble(data["ヘマトクリット(Ht)"]) { labData.hematocrit = NSNumber(value: value) }
            if let value = parseDouble(data["血小板数"]) { labData.platelet = NSNumber(value: value) }
            if let value = parseDouble(data["総蛋白(TP)"]) { labData.totalProtein = NSNumber(value: value) }
            if let value = parseDouble(data["尿酸(UA)"]) { labData.uricAcid = NSNumber(value: value) }
            if let value = parseDouble(data["尿素窒素(UN)"]) { labData.urea = NSNumber(value: value) }
            if let value = parseDouble(data["クレアチニン(CREA)"]) { labData.creatinine = NSNumber(value: value) }
            if let value = parseDouble(data["総コレステロール"]) { labData.totalCholesterol = NSNumber(value: value) }
            if let value = parseDouble(data["中性脂肪(TG)"]) { labData.triglycerides = NSNumber(value: value) }
            if let value = parseDouble(data["総ビリルビン"]) { labData.totalBilirubin = NSNumber(value: value) }
            if let value = parseDouble(data["AST(GOT)"]) { labData.ast = NSNumber(value: value) }
            if let value = parseDouble(data["ALT(GPT)"]) { labData.alt = NSNumber(value: value) }
            if let value = parseDouble(data["ALP"]) { labData.alp = NSNumber(value: value) }
            if let value = parseDouble(data["γ-GTP"]) { labData.gammaGtp = NSNumber(value: value) }
            if let value = parseDouble(data["空腹時血糖"]) { labData.fastingBloodSugar = NSNumber(value: value) }
            if let value = parseDouble(data["HbA1c"]) { labData.hba1c = NSNumber(value: value) }
            
            labData.bloodTypeAbo = data["血液型(ABO)"]
            labData.bloodTypeRh = data["血液型(Rh)"]
            labData.hbsAntigenResult = data["HBs抗原"]
            labData.hcvAntibodyResult = data["HCV抗体"]
            labData.syphilisTpResult = data["梅毒TP抗体"]
            labData.hivResult = data["HIV抗体"]
        }
        
        // Follow-up data (if exists in CSV)
        if let followUpDate = parseDate(data["経過観察日"]) {
            let followUp = FollowUp(context: context)
            followUp.id = UUID()
            followUp.followUpDate = followUpDate
            followUp.measurementDate = followUpDate
            followUp.surgery = patient.surgeries?.allObjects.first as? Surgery
            
            // Calculate months after surgery
            if let surgery = patient.surgeries?.allObjects.first as? Surgery,
               let surgeryDate = surgery.surgeryDate {
                let months = Calendar.current.dateComponents([.month], from: surgeryDate, to: followUpDate).month ?? 0
                followUp.timing = "\(months)ヶ月後"
            }
            
            if let value = parseDouble(data["術後体重(kg)"]) {
                followUp.bodyWeight = NSNumber(value: value)
            }
            if let value = parseDouble(data["BreastQ Score"]) {
                followUp.breastQScore = NSNumber(value: value)
            }
            
            followUp.smokingStatus = data["喫煙状況"]
            followUp.alcoholConsumption = data["飲酒状況"]
            followUp.o2Capsule = data["O2カプセル"]
            followUp.notes = data["経過観察メモ"]
        }
    }
    
    // MARK: - Helper Functions
    private func parseCSVLine(_ line: String) -> [String] {
        var result: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                result.append(current.trimmingCharacters(in: .whitespaces))
                current = ""
            } else {
                current.append(char)
            }
        }
        result.append(current.trimmingCharacters(in: .whitespaces))
        return result
    }
    
    private func parseDouble(_ string: String?) -> Double? {
        guard let str = string, !str.isEmpty else { return nil }
        return Double(str.replacingOccurrences(of: ",", with: ""))
    }
    
    private func parseDate(_ string: String?) -> Date? {
        guard let str = string, !str.isEmpty else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        if let date = formatter.date(from: str) {
            return date
        }
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: str)
    }
}
