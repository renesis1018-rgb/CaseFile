//
//  LabDataParser.swift
//  CaseFile
//
//  血液検査データのパーサー（完璧版）
//  ✅ 全フィールド対応完了
//

import Foundation
import CoreData

struct ParsedLabDataItem {
    let fieldName: String
    let value: Any
    let originalLine: String
    let coreDataFieldName: String
}

struct ParsedLabData {
    let items: [ParsedLabDataItem]
    let testDate: Date
    let unmatchedLines: [String]
    let parsedCount: Int
}

class LabDataParser {
    
    // MARK: - フィールドマッピング（数値フィールド）
    private static let numericFieldMapping: [String: String] = [
        // 血球系
        "白血球数": "wbc", "WBC": "wbc",
        "赤血球数": "rbc", "RBC": "rbc",
        "血色素量": "hb", "Hb": "hb",
        "ヘマトクリット": "hematocrit", "Ht": "hematocrit",
        "MCV": "mcv", "MCH": "mch", "MCHC": "mchc",
        "血小板数": "platelet",
        
        // 凝固系
        "APTT": "aptt",
        "プロトロンビン時間": "prothrombinTime",
        "PT時間": "ptTime",
        "対照": "ptControl",
        "PT活性値": "ptActivity",
        "PT-INR": "ptInr",
        
        // 生化学
        "総蛋白": "totalProtein", "TP": "totalProtein",
        "AST": "ast", "GOT": "ast",
        "ALT": "alt", "GPT": "alt",
        "LD": "ldh", "LD/IFCC": "ldh", "LDH": "ldh",
        "ALP": "alp", "ALP/IFCC": "alp",
        "γ-GT": "gammaGtp", "γ-GTP": "gammaGtp",
        
        // ビリルビン
        "総ビリルビン": "totalBilirubin",
        "直接ビリルビン": "directBilirubin",
        "I-BIL": "indirectBilirubin",
        "間接ビリルビン": "indirectBilirubin",
        
        // 腎機能
        "クレアチニン": "creatinine", "CREA": "creatinine",
        "尿素窒素": "un", "UN": "un",
        "尿酸": "uricAcid", "UA": "uricAcid",
        
        // 脂質
        "総コレステロール": "totalCholesterol",
        "総コレステロ-ル": "totalCholesterol",
        "中性脂肪": "triglyceride", "TG": "triglyceride",
        
        // 電解質
        "ナトリウム": "sodium", "Na": "sodium",
        "カリウム": "potassium", "K": "potassium",
        "クロール": "chloride", "Cl": "chloride",
        "鉄": "iron", "Fe": "iron",
        
        // 糖代謝
        "血糖": "glucose",
        "血糖(空腹時)": "glucose",
        "空腹時血糖": "fastingBloodSugar",
        "HbA1c(NGSP)": "hba1c",
        "HbA1c": "hba1c",
        
        // 感染症（定量値） - 階層構造に完全対応
        "HBs抗原/CLIA 定量値": "hbsAntigenValue",  // 🔧 追加
        "HCV抗体 3rd インデックス": "hcvAntibodyIndex"  // 🔧 追加
    ]
    
    // MARK: - 文字列フィールドマッピング
    private static let stringFieldMapping: [String: String] = [
        "RPR法 定性": "rprResult",
        "梅毒TP抗体定性": "syphilisTpResult",
        "血液型 ABO式": "bloodTypeAbo",
        "血液型 Rh(D)式": "bloodTypeRh",
        "HBs抗原/CLIA 判定": "hbsAntigenResult",
        "HBs抗体/CLIA 判定": "hbsAntibodyResult",
        "HBs抗体/CLIA 定量値": "hbsAntibodyValue",  // String型
        "HCV抗体 3rd 判定": "hcvAntibodyResult",
        "HCV抗体 3rd ユニット": "hcvAntibodyUnit",
        "HIV抗原・抗体同時定性": "hivResult"
    ]
    
    // MARK: - パース処理
    func parse(_ text: String, testDate: Date = Date()) -> ParsedLabData {
        var items: [ParsedLabDataItem] = []
        var unmatchedLines: [String] = []
        
        let lines = text.components(separatedBy: .newlines)
        var lastMainCategory: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            let columns = line.components(separatedBy: "\t")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            
            guard columns.count >= 2 else {
                unmatchedLines.append(line)
                continue
            }
            
            let itemName = columns[0]
            
            // 階層構造の判定
            let originalItemName = line.components(separatedBy: "\t")[0]
            let isSubItem = originalItemName.starts(with: " ") || originalItemName.starts(with: "\t")
            
            if !isSubItem {
                lastMainCategory = itemName.trimmingCharacters(in: .whitespaces)
            }
            
            let fullItemName: String
            if isSubItem, let parent = lastMainCategory {
                let subName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
                fullItemName = "\(parent) \(subName)"
            } else {
                fullItemName = itemName.trimmingCharacters(in: .whitespaces)
            }
            
            let valueString = columns[1]
            
            if valueString.isEmpty || valueString == ", true" {
                continue
            }
            
            // 文字列フィールドの処理（優先）
            if let coreDataField = matchStringFieldName(fullItemName) {
                let cleanedValue = cleanStringValue(valueString)
                
                let item = ParsedLabDataItem(
                    fieldName: fullItemName,
                    value: cleanedValue,
                    originalLine: line,
                    coreDataFieldName: coreDataField
                )
                items.append(item)
                print("✅ [String] \(fullItemName) → \(coreDataField) = \(cleanedValue)")
                continue
            }
            
            // 数値フィールドの処理
            if let coreDataField = matchNumericFieldName(fullItemName) {
                guard let value = extractNumber(from: valueString) else {
                    unmatchedLines.append(line)
                    continue
                }
                
                let item = ParsedLabDataItem(
                    fieldName: fullItemName,
                    value: value,
                    originalLine: line,
                    coreDataFieldName: coreDataField
                )
                items.append(item)
                print("✅ [Double] \(fullItemName) → \(coreDataField) = \(value)")
                continue
            }
            
            unmatchedLines.append(line)
            print("⚠️ マッチなし: \(fullItemName) (値: \(valueString))")
        }
        
        print("📊 パース結果: 成功 \(items.count) 件、未マッチ \(unmatchedLines.count) 件")
        
        return ParsedLabData(
            items: items,
            testDate: testDate,
            unmatchedLines: unmatchedLines,
            parsedCount: items.count
        )
    }
    
    // MARK: - ヘルパーメソッド
    
    private func matchNumericFieldName(_ name: String) -> String? {
        // 完全一致を優先
        if let field = Self.numericFieldMapping[name] {
            return field
        }
        
        // 部分一致（長いキーを優先）
        let matches = Self.numericFieldMapping.filter { key, _ in
            name.contains(key)
        }.sorted { $0.key.count > $1.key.count }
        
        return matches.first?.value
    }
    
    private func matchStringFieldName(_ name: String) -> String? {
        // 完全一致を優先
        if let field = Self.stringFieldMapping[name] {
            return field
        }
        
        // 部分一致（長いキーを優先）
        let matches = Self.stringFieldMapping.filter { key, _ in
            name.contains(key)
        }.sorted { $0.key.count > $1.key.count }
        
        return matches.first?.value
    }
    
    private func extractNumber(from string: String) -> Double? {
        let cleaned = string
            .replacingOccurrences(of: "(+)", with: "")
            .replacingOccurrences(of: "(-)", with: "")
            .replacingOccurrences(of: "<", with: "")
            .replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "LT", with: "")
            .replacingOccurrences(of: "H", with: "")
            .replacingOccurrences(of: "L", with: "")
            .replacingOccurrences(of: "↑", with: "")
            .replacingOccurrences(of: "↓", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        if cleaned == "0" {
            return nil
        }
        
        return Double(cleaned)
    }
    
    private func cleanStringValue(_ string: String) -> String {
        return string
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ", true", with: "")
    }
    
    // MARK: - Core Data への保存
    func saveToLabData(_ parsedData: ParsedLabData, patient: Patient, context: NSManagedObjectContext) throws -> LabData {
        let labData = LabData(context: context)
        labData.id = UUID()
        labData.patient = patient
        labData.testDate = parsedData.testDate
        
        var savedCount = 0
        var errorFields: [String] = []
        
        for item in parsedData.items {
            do {
                if let doubleValue = item.value as? Double {
                    let nsNumber = NSNumber(value: doubleValue)
                    labData.setValue(nsNumber, forKey: item.coreDataFieldName)
                } else if let stringValue = item.value as? String {
                    labData.setValue(stringValue, forKey: item.coreDataFieldName)
                }
                savedCount += 1
            } catch {
                errorFields.append(item.coreDataFieldName)
                print("❌ フィールド設定エラー: \(item.coreDataFieldName) - \(error)")
            }
        }
        
        print("✅ LabData saved: \(savedCount) items for patient \(patient.patientId ?? "unknown")")
        if !errorFields.isEmpty {
            print("⚠️ 保存失敗フィールド: \(errorFields.joined(separator: ", "))")
        }
        if !parsedData.unmatchedLines.isEmpty {
            print("⚠️ マッチしなかった行 (\(parsedData.unmatchedLines.count) 件):")
            for line in parsedData.unmatchedLines.prefix(5) {
                print("  • \(line)")
            }
            if parsedData.unmatchedLines.count > 5 {
                print("  ... 他 \(parsedData.unmatchedLines.count - 5) 件")
            }
        }
        
        try context.save()
        
        return labData
    }
}
