import Foundation
import CoreData
import CoreXLSX
import Combine

class CSVImporterManager: ObservableObject {
    @Published var importResult: String = ""
    @Published var isImporting: Bool = false
    @Published var importedCounts: [String: Int] = [:]
    @Published var errorMessages: [String] = []
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    // CSVImportView.swift が呼び出すメソッド
    func importExcelFile(at url: URL) {
        isImporting = true
        importedCounts = [:]
        errorMessages = []
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.importExcel(from: url)
            
            DispatchQueue.main.async {
                self?.isImporting = false
            }
        }
    }
    
    private func importExcel(from url: URL) {
        // ✅ 修正: Background Context を作成
        let backgroundContext = PersistenceController.shared.container.newBackgroundContext()
        backgroundContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        backgroundContext.performAndWait {
            do {
                guard let file = XLSXFile(filepath: url.path) else {
                    DispatchQueue.main.async {
                        self.importResult = "❌ Cannot open Excel file"
                        self.errorMessages.append("Cannot open Excel file")
                    }
                    return
                }
                
                // SharedStrings の読み込み
                let sharedStrings = try file.parseSharedStrings()
                print("✅ SharedStrings loaded: \(sharedStrings?.uniqueCount ?? 0) items")
                
                // ワークシートパスを取得
                let worksheetPaths = try file.parseWorksheetPaths()
                print("✅ Worksheet count: \(worksheetPaths.count)")
                
                // 各シートの種類を判定
                var patientsSheet: String?
                var surgeriesSheet: String?
                var labDataSheet: String?
                var followUpsSheet: String?
                
                for path in worksheetPaths {
                    let worksheet = try file.parseWorksheet(at: path)
                    
                    // 1行目のヘッダーを確認
                    let firstRow = worksheet.data?.rows.first
                    if let cells = firstRow?.cells {
                        let headers = cells.compactMap { cell -> String? in
                            guard let sharedStrings = sharedStrings else { return nil }
                            return cell.stringValue(sharedStrings)
                        }
                        
                        print("📋 Sheet \(path) headers: \(headers.prefix(5))")
                        
                        // ヘッダーで判定
                        if headers.contains("患者ID") && headers.contains("年齢") && headers.contains("登録日") {
                            patientsSheet = path
                            print("📋 Patients sheet found: \(path)")
                        } else if headers.contains("術式") && headers.contains("手術日") && headers.contains("手術カテゴリ") {
                            surgeriesSheet = path
                            print("📋 Surgeries sheet found: \(path)")
                        } else if headers.contains("検査日") && headers.contains("白血球数(WBC)") {
                            labDataSheet = path
                            print("📋 LabData sheet found: \(path)")
                        } else if headers.contains("フォローアップ日") && headers.contains("VECTRA体積(R)") {
                            followUpsSheet = path
                            print("📋 FollowUps sheet found: \(path)")
                        }
                    }
                }
                
                // 正しい順序で処理（backgroundContext を使用）
                var stats = [String: Int]()
                
                if let path = patientsSheet {
                    stats["Patients"] = try self.importPatients(from: file, path: path, sharedStrings: sharedStrings, context: backgroundContext)
                }
                
                if let path = surgeriesSheet {
                    stats["Surgeries"] = try self.importSurgeries(from: file, path: path, sharedStrings: sharedStrings, context: backgroundContext)
                }
                
                if let path = labDataSheet {
                    stats["LabData"] = try self.importLabData(from: file, path: path, sharedStrings: sharedStrings, context: backgroundContext)
                }
                
                if let path = followUpsSheet {
                    stats["FollowUps"] = try self.importFollowUps(from: file, path: path, sharedStrings: sharedStrings, context: backgroundContext)
                }
                
                // ✅ 修正: Background Context で保存
                do {
                    try backgroundContext.save()
                    print("✅ All data saved successfully in background context")
                } catch {
                    print("❌ Final save error: \(error)")
                    throw error
                }
                
                // 結果をメインスレッドで更新
                DispatchQueue.main.async {
                    self.importedCounts = stats
                    
                    var result = "インポート結果:\n"
                    for (key, value) in stats.sorted(by: { $0.key < $1.key }) {
                        result += "\(key): \(value)件\n"
                    }
                    self.importResult = result
                }
                
            } catch {
                DispatchQueue.main.async {
                    self.importResult = "❌ Excel import error: \(error.localizedDescription)"
                    self.errorMessages.append("Excel import error: \(error.localizedDescription)")
                }
                print("❌ Excel import error: \(error)")
            }
        }
    }
    
    // MARK: - Helper: Column letter to index
    private func columnLetterToIndex(_ letter: String) -> Int? {
        var index = 0
        for char in letter.uppercased() {
            guard let value = char.asciiValue, value >= 65, value <= 90 else {
                return nil
            }
            index = index * 26 + Int(value - 64)
        }
        return index - 1
    }
    
    // MARK: - Helper: Date parsing
    private func dateValue(from cell: Cell, sharedStrings: SharedStrings?) -> Date? {
        if let dateValue = cell.dateValue {
            return dateValue
        }
        
        guard let sharedStrings = sharedStrings else { return nil }
        
        if let stringValue = cell.stringValue(sharedStrings) {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            
            let formats = ["yyyy-MM-dd", "yyyy/MM/dd", "MM/dd/yyyy", "dd.MM.yyyy"]
            for format in formats {
                formatter.dateFormat = format
                if let date = formatter.date(from: stringValue) {
                    return date
                }
            }
            
            if let excelSerial = Double(stringValue) {
                let baseDate = Date(timeIntervalSince1970: -2209161600)
                return baseDate.addingTimeInterval(TimeInterval((excelSerial - 1) * 86400))
            }
        }
        
        return nil
    }
    
    // MARK: - Import Patients
    private func importPatients(from file: XLSXFile, path: String, sharedStrings: SharedStrings?, context: NSManagedObjectContext) throws -> Int {
        print("📄 Processing Patients: \(path)")
        
        let worksheet = try file.parseWorksheet(at: path)
        guard let sheetData = worksheet.data else { return 0 }
        guard let sharedStrings = sharedStrings else { return 0 }
        
        var count = 0
        
        for (index, row) in sheetData.rows.enumerated() {
            if index == 0 { continue }
            
            let cells = row.cells
            guard cells.count > 0 else { continue }
            
            var cellMap: [Int: String] = [:]
            for cell in cells {
                if let columnLetter = cell.reference.column.value as? String,
                   let colIndex = columnLetterToIndex(columnLetter) {
                    cellMap[colIndex] = cell.stringValue(sharedStrings) ?? ""
                }
            }
            
            guard let patientId = cellMap[0], !patientId.isEmpty else { continue }
            
            let fetchRequest: NSFetchRequest<Patient> = Patient.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "patientId == %@", patientId)
            
            let existingPatients = try context.fetch(fetchRequest)
            let patient = existingPatients.first ?? Patient(context: context)
            
            patient.patientId = patientId
            
            // Patients シート: A=患者ID, B=年齢, C=性別, D=連絡先, E=登録日, F=備考
            if let ageStr = cellMap[1], let age = Int16(ageStr) {
                patient.age = NSNumber(value: age)
            }
            patient.gender = cellMap[2]
            patient.contactInfo = cellMap[3]
            
            // 登録日（列E = index 4）
            for cell in cells {
                if let columnLetter = cell.reference.column.value as? String,
                   let colIndex = columnLetterToIndex(columnLetter),
                   colIndex == 4 {
                    patient.registeredDate = dateValue(from: cell, sharedStrings: sharedStrings)
                    break
                }
            }
            
            patient.notes = cellMap[5]
            
            // 氏名フィールドが存在しないため、デフォルト値を設定
            if patient.name == nil || patient.name?.isEmpty == true {
                patient.name = "患者\(patientId)"
            }
            
            count += 1
        }
        
        print("✅ Patients created: \(count)")
        return count
    }
    
    // MARK: - Import Surgeries
    private func importSurgeries(from file: XLSXFile, path: String, sharedStrings: SharedStrings?, context: NSManagedObjectContext) throws -> Int {
        print("📄 Processing Surgeries: \(path)")
        
        let worksheet = try file.parseWorksheet(at: path)
        guard let sheetData = worksheet.data else { return 0 }
        guard let sharedStrings = sharedStrings else { return 0 }
        
        var count = 0
        
        for (index, row) in sheetData.rows.enumerated() {
            if index == 0 { continue }
            
            let cells = row.cells
            guard cells.count > 0 else { continue }
            
            var cellMap: [Int: String] = [:]
            for cell in cells {
                if let columnLetter = cell.reference.column.value as? String,
                   let colIndex = columnLetterToIndex(columnLetter) {
                    cellMap[colIndex] = cell.stringValue(sharedStrings) ?? ""
                }
            }
            
            guard let patientId = cellMap[0], !patientId.isEmpty else { continue }
            
            let fetchRequest: NSFetchRequest<Patient> = Patient.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "patientId == %@", patientId)
            
            guard let patient = try context.fetch(fetchRequest).first else {
                print("⚠️ Patient not found: \(patientId)")
                continue
            }
            
            let surgery = Surgery(context: context)
            surgery.id = UUID()
            surgery.patient = patient
            
            // 🆕 新しい列マッピング(2025年12月24日版)
            surgery.surgeryCategory = cellMap[1]  // B列: 手術カテゴリ(大カテゴリ)
            surgery.surgeryType = cellMap[2]  // C列: 術式(術式詳細)
            
            // ✅ 修正: 手入力と同じ形式で保存(例: "脂肪注入 (Condense)")
            if let procedureType = cellMap[3], !procedureType.isEmpty {
                let surgeryTypeValue = cellMap[2] ?? "脂肪注入"
                surgery.procedure = "\(surgeryTypeValue) (\(procedureType))"
            } else {
                surgery.procedure = cellMap[3]  // D列: 脂肪注入種別
            }
            
            print("✅ Surgery data for patient \(patientId):")
            print("   - surgeryCategory: \(surgery.surgeryCategory ?? "nil")")
            print("   - surgeryType: \(surgery.surgeryType ?? "nil")")
            print("   - procedure: \(surgery.procedure ?? "nil")")
            
            if let bmiStr = cellMap[4], let bmi = Double(bmiStr) {  // E列: BMI
                surgery.bmi = NSNumber(value: bmi)
            }
            
            surgery.anesthesiaMethod = cellMap[5]  // F列: 麻酔方法
            surgery.implantManufacturer = cellMap[6]  // G列: インプラントメーカー
            
            // H列(7), I列(8): VECTRA術前
            var hasVectra = false
            if let vectraRStr = cellMap[7], let value = Double(vectraRStr) {
                surgery.preOpVectraR = NSNumber(value: value)
                hasVectra = true
                print("✅ VECTRA Right: \(value) for patient \(patientId)")
            }
            if let vectraLStr = cellMap[8], let value = Double(vectraLStr) {
                surgery.preOpVectraL = NSNumber(value: value)
                hasVectra = true
                print("✅ VECTRA Left: \(value) for patient \(patientId)")
            }
            surgery.preOpVectra = NSNumber(value: hasVectra)
            
            // J列(9): 手術日
            for cell in cells {
                if let columnLetter = cell.reference.column.value as? String,
                   let colIndex = columnLetterToIndex(columnLetter),
                   colIndex == 9 {
                    surgery.surgeryDate = dateValue(from: cell, sharedStrings: sharedStrings)
                    break
                }
            }
            
            // K列(10): 手術種別(重複のため使用しない)
            surgery.smokingHistory = cellMap[11]  // L列: 喫煙歴
            surgery.breastfeedingHistory = cellMap[12]  // M列: 授乳歴
            
            if let countStr = cellMap[13], let count = Int16(countStr) {  // N列: 手術回数
                surgery.numberOfProcedures = NSNumber(value: count)
            }
            
            if let heightStr = cellMap[14], let height = Double(heightStr) {  // O列: 身長
                surgery.height = NSNumber(value: height)
            }
            
            if let weightStr = cellMap[15], let weight = Double(weightStr) {  // P列: 体重
                surgery.bodyWeight = NSNumber(value: weight)
            }
            
            if let nacRStr = cellMap[16], let value = Double(nacRStr) {  // Q列: NAC-IMF(R)
                surgery.nacImfRight = NSNumber(value: value)
            }
            
            if let nacStretchRStr = cellMap[17], let value = Double(nacStretchRStr) {  // R列: NAC-IMFon stretch(R)
                surgery.nacImfStretchRight = NSNumber(value: value)
            }
            
            if let nacLStr = cellMap[18], let value = Double(nacLStr) {  // S列: NAC-IMF(L)
                surgery.nacImfLeft = NSNumber(value: value)
            }
            
            if let nacStretchLStr = cellMap[19], let value = Double(nacStretchLStr) {  // T列: NAC-IMFon stretch(L)
                surgery.nacImfStretchLeft = NSNumber(value: value)
            }
            
            if let skinRStr = cellMap[20], let value = Double(skinRStr) {  // U列: skin thickness(R)
                surgery.skinThicknessRight = NSNumber(value: value)
            }
            
            if let skinLStr = cellMap[21], let value = Double(skinLStr) {  // V列: skin thickness(L)
                surgery.skinThicknessLeft = NSNumber(value: value)
            }
            
            surgery.donorSite = cellMap[22]  // W列: 採取部位
            
            if let injRStr = cellMap[23], let value = Double(injRStr) {  // X列: Injection Volume(R)
                surgery.injectionVolumeR = NSNumber(value: value)
            }
            
            if let injLStr = cellMap[24], let value = Double(injLStr) {  // Y列: Injection Volume(L)
                surgery.injectionVolumeL = NSNumber(value: value)
            }
            
            if let subRStr = cellMap[25], let value = Double(subRStr) {  // Z列: 皮下(R)
                surgery.subcutaneousRight = NSNumber(value: value)
            }
            
            if let glandRStr = cellMap[26], let value = Double(glandRStr) {  // AA列: 乳腺下（R）
                surgery.subglandularRight = NSNumber(value: value)
            }
            
            if let muscRStr = cellMap[27], let value = Double(muscRStr) {  // AB列: 大胸筋内下（R）
                surgery.submuscularRight = NSNumber(value: value)
            }
            
            if let subLStr = cellMap[28], let value = Double(subLStr) {  // AC列: 皮下（L）
                surgery.subcutaneousLeft = NSNumber(value: value)
            }
            
            if let glandLStr = cellMap[29], let value = Double(glandLStr) {  // AD列: 乳腺下（L）
                surgery.subglandularLeft = NSNumber(value: value)
            }
            
            if let muscLStr = cellMap[30], let value = Double(muscLStr) {  // AE列: 大胸筋内下（L）
                surgery.submuscularLeft = NSNumber(value: value)
            }
            
            if let decoRStr = cellMap[31], let value = Double(decoRStr) {  // AF列: デコルテ（R）
                surgery.decolletRight = NSNumber(value: value)
            }
            
            if let decoLStr = cellMap[32], let value = Double(decoLStr) {  // AG列: デコルテ（L）
                surgery.decolletLeft = NSNumber(value: value)
            }
            
            surgery.notes = cellMap[33]  // AH列: 備考
            surgery.createdDate = surgery.createdDate ?? Date()
            
            count += 1
        }
        
        print("✅ Surgeries created: \(count)")
        return count
    }
    
    // MARK: - Import LabData
    private func importLabData(from file: XLSXFile, path: String, sharedStrings: SharedStrings?, context: NSManagedObjectContext) throws -> Int {
        print("📄 Processing LabData: \(path)")
        
        let worksheet = try file.parseWorksheet(at: path)
        guard let sheetData = worksheet.data else { return 0 }
        guard let sharedStrings = sharedStrings else { return 0 }
        
        var count = 0
        
        for (index, row) in sheetData.rows.enumerated() {
            if index == 0 { continue }
            
            let cells = row.cells
            guard cells.count > 0 else { continue }
            
            var cellMap: [Int: String] = [:]
            for cell in cells {
                if let columnLetter = cell.reference.column.value as? String,
                   let colIndex = columnLetterToIndex(columnLetter) {
                    cellMap[colIndex] = cell.stringValue(sharedStrings) ?? ""
                }
            }
            
            guard let patientId = cellMap[0], !patientId.isEmpty else { continue }
            
            let fetchRequest: NSFetchRequest<Patient> = Patient.fetchRequest()
            fetchRequest.predicate = NSPredicate(format: "patientId == %@", patientId)
            
            guard let patient = try context.fetch(fetchRequest).first else {
                print("⚠️ Patient not found: \(patientId)")
                continue
            }
            
            let labData = LabData(context: context)
            labData.id = UUID()  // 必須フィールド
            labData.patient = patient
            
            for cell in cells {
                if let columnLetter = cell.reference.column.value as? String,
                   let colIndex = columnLetterToIndex(columnLetter),
                   colIndex == 1 {
                    labData.testDate = dateValue(from: cell, sharedStrings: sharedStrings)
                    break
                }
            }
            
            if let wbcStr = cellMap[2], let value = Double(wbcStr) { labData.wbc = NSNumber(value: value) }
            if let rbcStr = cellMap[3], let value = Double(rbcStr) { labData.rbc = NSNumber(value: value) }
            if let hbStr = cellMap[4], let value = Double(hbStr) { labData.hb = NSNumber(value: value) }  // 血色素量(Hb)
            if let hctStr = cellMap[5], let value = Double(hctStr) { labData.hematocrit = NSNumber(value: value) }
            if let mcvStr = cellMap[6], let value = Double(mcvStr) { labData.mcv = NSNumber(value: value) }
            if let mchStr = cellMap[7], let value = Double(mchStr) { labData.mch = NSNumber(value: value) }
            if let mchcStr = cellMap[8], let value = Double(mchcStr) { labData.mchc = NSNumber(value: value) }
            if let pltStr = cellMap[9], let value = Double(pltStr) { labData.platelet = NSNumber(value: value) }
            
            // PT関連
            if let ptTimeStr = cellMap[10], let value = Double(ptTimeStr) { labData.ptTime = NSNumber(value: value) }
            if let ptControlStr = cellMap[11], let value = Double(ptControlStr) { labData.ptControl = NSNumber(value: value) }
            if let ptActivityStr = cellMap[12], let value = Double(ptActivityStr) { labData.ptActivity = NSNumber(value: value) }
            if let ptInrStr = cellMap[13], let value = Double(ptInrStr) { labData.ptInr = NSNumber(value: value) }
            
            if let apttStr = cellMap[14], let value = Double(apttStr) { labData.aptt = NSNumber(value: value) }
            if let tpStr = cellMap[15], let value = Double(tpStr) { labData.totalProtein = NSNumber(value: value) }
            if let uaStr = cellMap[16], let value = Double(uaStr) { labData.uricAcid = NSNumber(value: value) }
            if let unStr = cellMap[17], let value = Double(unStr) { labData.un = NSNumber(value: value) }
            if let indBilStr = cellMap[18], let value = Double(indBilStr) { labData.indirectBilirubin = NSNumber(value: value) }
            if let crStr = cellMap[19], let value = Double(crStr) { labData.creatinine = NSNumber(value: value) }
            
            // 電解質
            if let naStr = cellMap[20], let value = Double(naStr) { labData.sodium = NSNumber(value: value) }
            if let kStr = cellMap[21], let value = Double(kStr) { labData.potassium = NSNumber(value: value) }
            if let clStr = cellMap[22], let value = Double(clStr) { labData.chloride = NSNumber(value: value) }
            
            if let feStr = cellMap[23], let value = Double(feStr) { labData.iron = NSNumber(value: value) }
            if let tcStr = cellMap[24], let value = Double(tcStr) { labData.totalCholesterol = NSNumber(value: value) }
            if let tgStr = cellMap[25], let value = Double(tgStr) { labData.triglyceride = NSNumber(value: value) }
            if let tbStr = cellMap[26], let value = Double(tbStr) { labData.totalBilirubin = NSNumber(value: value) }
            if let dbStr = cellMap[27], let value = Double(dbStr) { labData.directBilirubin = NSNumber(value: value) }
            if let astStr = cellMap[28], let value = Double(astStr) { labData.ast = NSNumber(value: value) }
            if let altStr = cellMap[29], let value = Double(altStr) { labData.alt = NSNumber(value: value) }
            if let gammaGtpStr = cellMap[30], let value = Double(gammaGtpStr) { labData.gammaGtp = NSNumber(value: value) }  // γ-GT
            if let glucStr = cellMap[31], let value = Double(glucStr) { labData.glucose = NSNumber(value: value) }
            
            // HBs関連
            labData.hbsAntigenResult = cellMap[32]  // HBs抗原判定
            if let hbsAgValueStr = cellMap[33], let value = Double(hbsAgValueStr) { labData.hbsAntigenValue = NSNumber(value: value) }
            labData.hbsAntibodyResult = cellMap[34]  // HBs抗体判定
            labData.hbsAntibodyValue = cellMap[35]  // HBs抗体定量値
            
            labData.bloodTypeAbo = cellMap[36]  // 血液型 ABO式
            labData.bloodTypeRh = cellMap[37]  // 血液型 Rh(D)式
            labData.rprResult = cellMap[38]  // RPR法 定性
            labData.syphilisTpResult = cellMap[39]  // 梅毒TP抗体定性
            
            if let hba1cStr = cellMap[40], let value = Double(hba1cStr) { labData.hba1c = NSNumber(value: value) }
            
            // HCV関連
            labData.hcvAntibodyResult = cellMap[41]  // HCV抗体判定
            if let hcvIndexStr = cellMap[42], let value = Double(hcvIndexStr) { labData.hcvAntibodyIndex = NSNumber(value: value) }
            labData.hcvAntibodyUnit = cellMap[43]  // HCV抗体ユニット
            
            labData.hivResult = cellMap[44]  // HIV抗原・抗体同時定性
            
            if let alpStr = cellMap[45], let value = Double(alpStr) { labData.alp = NSNumber(value: value) }
            if let ldhStr = cellMap[46], let value = Double(ldhStr) { labData.ldh = NSNumber(value: value) }
            
            count += 1
        }
        
        print("✅ LabData created: \(count)")
        return count
    }
    
    // MARK: - Import FollowUps
    private func importFollowUps(from file: XLSXFile, path: String, sharedStrings: SharedStrings?, context: NSManagedObjectContext) throws -> Int {
        print("📄 Processing FollowUps: \(path)")
        
        let worksheet = try file.parseWorksheet(at: path)
        guard let sheetData = worksheet.data else { return 0 }
        guard let sharedStrings = sharedStrings else { return 0 }
        
        var count = 0
        
        for (index, row) in sheetData.rows.enumerated() {
            if index == 0 { continue }
            
            let cells = row.cells
            guard cells.count > 0 else { continue }
            
            var cellMap: [Int: String] = [:]
            var surgeryDateFromCell: Date?
            var followUpDateFromCell: Date?
            var measurementDateFromCell: Date?
            
            for cell in cells {
                if let columnLetter = cell.reference.column.value as? String,
                   let colIndex = columnLetterToIndex(columnLetter) {
                    cellMap[colIndex] = cell.stringValue(sharedStrings) ?? ""
                    
                    if colIndex == 1 {
                        surgeryDateFromCell = dateValue(from: cell, sharedStrings: sharedStrings)
                    } else if colIndex == 2 {
                        followUpDateFromCell = dateValue(from: cell, sharedStrings: sharedStrings)
                    } else if colIndex == 3 {
                        measurementDateFromCell = dateValue(from: cell, sharedStrings: sharedStrings)
                    }
                }
            }
            
            guard let patientId = cellMap[0], !patientId.isEmpty else { continue }
            guard let surgeryDate = surgeryDateFromCell else { continue }
            
            let patientFetch: NSFetchRequest<Patient> = Patient.fetchRequest()
            patientFetch.predicate = NSPredicate(format: "patientId == %@", patientId)
            
            guard let patient = try context.fetch(patientFetch).first else {
                print("⚠️ Patient not found: \(patientId)")
                continue
            }
            
            let surgeryFetch: NSFetchRequest<Surgery> = Surgery.fetchRequest()
            surgeryFetch.predicate = NSPredicate(format: "patient == %@ AND surgeryDate == %@", patient, surgeryDate as NSDate)
            
            guard let surgery = try context.fetch(surgeryFetch).first else {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                print("⚠️ Surgery not found for patient \(patientId) on \(dateFormatter.string(from: surgeryDate))")
                continue
            }
            
            let followUp = FollowUp(context: context)
            followUp.id = UUID()  // OptionalだがUUIDを設定
            followUp.surgery = surgery
            followUp.followUpDate = followUpDateFromCell
            followUp.measurementDate = measurementDateFromCell
            followUp.timing = cellMap[4]
            
            // ✅ 修正: 正しいフィールド名に変更
            if let vectraRStr = cellMap[5], let value = Double(vectraRStr) {
                followUp.postOpVectraR = NSNumber(value: value)
                print("  - postOpVectraR: \(value)")
            }
            if let vectraLStr = cellMap[6], let value = Double(vectraLStr) {
                followUp.postOpVectraL = NSNumber(value: value)
                print("  - postOpVectraL: \(value)")
            }
            if let bwStr = cellMap[9], let value = Double(bwStr) {
                followUp.bodyWeight = NSNumber(value: value)
                print("  - bodyWeight: \(value)")
            }
            
            followUp.notes = cellMap[10]
            
            count += 1
        }
        
        print("✅ FollowUps created: \(count)")
        return count
    }
}
