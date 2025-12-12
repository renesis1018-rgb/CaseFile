//
//  AddSurgeryView.swift
//  CaseFile
//
//  新規手術登録画面(動的フォーム対応)
//

import SwiftUI
import CoreData

struct AddSurgeryView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var patient: Patient
    let context: NSManagedObjectContext
    
    // MARK: - 基本情報
    @State private var surgeryDate = Date()
    @State private var surgeryCategory = "豊胸系"
    @State private var surgeryType = "脂肪注入"
    @State private var fatInjectionSubType = "PureGraft"
    
    // MARK: - 目元系
    @State private var eyeSurgeryType = "埋没二重"
    
    // MARK: - その他共通項目
    @State private var notes = ""
    
    // MARK: - 患者基礎情報
    @State private var heightCm = ""
    @State private var bodyWeight = ""
    
    // MARK: - 豊胸系 - 喫煙歴・授乳歴・手術回数
    @State private var smokingHistory = "Never"
    @State private var breastfeedingHistory = "0回"
    @State private var numberOfProcedures = "1回目"
    
    // MARK: - 脂肪注入系
    @State private var donorSite = "大腿前面"
    @State private var injectionVolumeR = ""
    @State private var injectionVolumeL = ""
    @State private var subcutaneousR = ""
    @State private var subcutaneousL = ""
    @State private var subglandularR = ""
    @State private var subglandularL = ""
    @State private var submuscularR = ""
    @State private var submuscularL = ""
    @State private var decolleteR = ""
    @State private var decolleteL = ""
    @State private var vectraUsed = false
    @State private var preOpVectraR = ""
    @State private var preOpVectraL = ""
    @State private var nacImfRight = ""
    @State private var nacImfLeft = ""
    @State private var nacImfStretchRight = ""
    @State private var nacImfStretchLeft = ""
    @State private var skinThicknessRight = ""
    @State private var skinThicknessLeft = ""
    
    // MARK: - 脂肪吸引
    @State private var selectedLiposuctionAreas: Set<String> = []
    @State private var liposuctionVolume = ""
    @State private var aquicellUsed = false
    @State private var vaserUsed = false
    
    let liposuctionAreas: [(category: String, items: [String])] = [
        ("上肢", ["二の腕", "肩", "肩甲骨横"]),
        ("体幹", ["腹", "ウエスト", "腰", "背中上", "背中下"]),
        ("下肢", ["大腿", "臀部", "膝", "下腿", "足首"])
    ]
    
    let fatInjectionDonorSites = ["大腿前面", "大腿後面", "大腿両面", "上腕", "その他"]
    let eyeSurgeryTypes = ["埋没二重", "全切開二重", "眉下切開", "裏ハムラ", "切開ハムラ"]
    
    // MARK: - シリコン
    @State private var implantSizeR = ""
    @State private var implantSizeL = ""
    @State private var incisionSite = "選択してください"
    @State private var insertionPlane = "選択してください"
    
    // MARK: - エラー表示
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // 基本情報セクション
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("基本情報")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            DatePicker("手術日", selection: $surgeryDate, displayedComponents: .date)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("手術カテゴリ")
                                    .font(.subheadline)
                                Picker("", selection: $surgeryCategory) {
                                    Text("豊胸系").tag("豊胸系")
                                    Text("目元系").tag("目元系")
                                    Text("脂肪吸引").tag("脂肪吸引")
                                    Text("その他").tag("その他")
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            if surgeryCategory == "豊胸系" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("術式")
                                        .font(.subheadline)
                                    Picker("", selection: $surgeryType) {
                                        Text("脂肪注入").tag("脂肪注入")
                                        Text("シリコン").tag("シリコン")
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            
                            if surgeryCategory == "豊胸系" && surgeryType == "脂肪注入" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("脂肪注入種別")
                                        .font(.subheadline)
                                    Picker("", selection: $fatInjectionSubType) {
                                        Text("PureGraft").tag("PureGraft")
                                        Text("Condense").tag("Condense")
                                        Text("ADRC").tag("ADRC")
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                            
                            if surgeryCategory == "目元系" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("術式")
                                        .font(.subheadline)
                                    Picker("", selection: $eyeSurgeryType) {
                                        ForEach(eyeSurgeryTypes, id: \.self) { type in
                                            Text(type).tag(type)
                                        }
                                    }
                                }
                            }
                            
                            if surgeryCategory == "脂肪吸引" {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("術式")
                                        .font(.subheadline)
                                    Picker("", selection: $surgeryType) {
                                        Text("美body").tag("美body")
                                        Text("Vaser").tag("Vaser")
                                        Text("Aquicell").tag("Aquicell")
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                        }
                        .padding()
                    }
                    .padding()
                    
                    if surgeryCategory == "豊胸系" {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("患者情報")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                HStack {
                                    Text("喫煙歴")
                                        .frame(width: 100, alignment: .leading)
                                    Picker("", selection: $smokingHistory) {
                                        Text("Never").tag("Never")
                                        Text("Ex-smoker").tag("Ex-smoker")
                                        Text("Current").tag("Current")
                                    }
                                }
                                
                                HStack {
                                    Text("授乳歴")
                                        .frame(width: 100, alignment: .leading)
                                    Picker("", selection: $breastfeedingHistory) {
                                        Text("0回").tag("0回")
                                        Text("1回").tag("1回")
                                        Text("2回").tag("2回")
                                        Text("3回以上").tag("3回以上")
                                    }
                                }
                                
                                HStack {
                                    Text("手術回数")
                                        .frame(width: 100, alignment: .leading)
                                    Picker("", selection: $numberOfProcedures) {
                                        Text("1回目").tag("1回目")
                                        Text("2回目").tag("2回目")
                                        Text("3回目").tag("3回目")
                                        Text("4回目以上").tag("4回目以上")
                                    }
                                }
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    
                    GroupBox {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("術前患者状態")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            HStack {
                                Text("身長")
                                    .frame(width: 80, alignment: .leading)
                                TextField("cm", text: $heightCm)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                Text("cm")
                            }
                            
                            HStack {
                                Text("体重")
                                    .frame(width: 80, alignment: .leading)
                                TextField("kg", text: $bodyWeight)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 100)
                                Text("kg")
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    if surgeryCategory == "豊胸系" {
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("術前測定値")
                                    .font(.headline)
                                    .padding(.bottom, 4)
                                
                                Toggle("Vectra使用", isOn: $vectraUsed)
                                
                                if vectraUsed {
                                    HStack {
                                        Text("Vectra術前(R)")
                                            .frame(width: 150, alignment: .leading)
                                        TextField("cc", text: $preOpVectraR)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 100)
                                    }
                                    HStack {
                                        Text("Vectra術前(L)")
                                            .frame(width: 150, alignment: .leading)
                                        TextField("cc", text: $preOpVectraL)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 100)
                                    }
                                }
                                
                                HStack {
                                    Text("NAC-IMF Right")
                                        .frame(width: 150, alignment: .leading)
                                    TextField("cm", text: $nacImfRight)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                }
                                HStack {
                                    Text("NAC-IMF Left")
                                        .frame(width: 150, alignment: .leading)
                                    TextField("cm", text: $nacImfLeft)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                }
                                
                                HStack {
                                    Text("NAC-IMF Stretch Right")
                                        .frame(width: 150, alignment: .leading)
                                    TextField("cm", text: $nacImfStretchRight)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                }
                                HStack {
                                    Text("NAC-IMF Stretch Left")
                                        .frame(width: 150, alignment: .leading)
                                    TextField("cm", text: $nacImfStretchLeft)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                }
                                
                                HStack {
                                    Text("皮膚厚 Right")
                                        .frame(width: 150, alignment: .leading)
                                    TextField("cm", text: $skinThicknessRight)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                }
                                HStack {
                                    Text("皮膚厚 Left")
                                        .frame(width: 150, alignment: .leading)
                                    TextField("cm", text: $skinThicknessLeft)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 100)
                                }
                            }
                            .padding()
                        }
                        .padding(.horizontal)
                        .padding(.bottom)
                    }
                    
                    if surgeryCategory == "豊胸系" && surgeryType == "脂肪注入" {
                        fatInjectionSection
                    } else if surgeryCategory == "豊胸系" && surgeryType == "シリコン" {
                        siliconeSection
                    } else if surgeryCategory == "脂肪吸引" {
                        liposuctionSection
                    } else if surgeryCategory == "目元系" {
                        eyeSection
                    } else if surgeryCategory == "その他" {
                        otherSection
                    }
                }
            }
            .navigationTitle("新規手術登録")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { saveSurgery() }
                }
            }
            .alert("エラー", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
        .frame(minWidth: 800, idealWidth: 900, minHeight: 700)
    }
    
    // MARK: - 各セクション
    
    private var fatInjectionSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("手術内容")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    Text("採取部位")
                        .frame(width: 100, alignment: .leading)
                    Picker("", selection: $donorSite) {
                        ForEach(fatInjectionDonorSites, id: \.self) { site in
                            Text(site).tag(site)
                        }
                    }
                    .frame(width: 200)
                }
                
                HStack {
                    Text("注入量(R)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $injectionVolumeR)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                HStack {
                    Text("注入量(L)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $injectionVolumeL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                
                HStack {
                    Text("皮下(R)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $subcutaneousR)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                HStack {
                    Text("皮下(L)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $subcutaneousL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                
                HStack {
                    Text("乳腺下(R)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $subglandularR)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                HStack {
                    Text("乳腺下(L)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $subglandularL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                
                HStack {
                    Text("筋肉下(R)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $submuscularR)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                HStack {
                    Text("筋肉下(L)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $submuscularL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                
                HStack {
                    Text("デコルテ(R)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $decolleteR)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                HStack {
                    Text("デコルテ(L)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $decolleteL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                
                Divider().padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("備考")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var siliconeSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("手術内容")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                HStack {
                    Text("インプラントサイズ(R)")
                        .frame(width: 160, alignment: .leading)
                    TextField("cc", text: $implantSizeR)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                HStack {
                    Text("インプラントサイズ(L)")
                        .frame(width: 160, alignment: .leading)
                    TextField("cc", text: $implantSizeL)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                
                HStack {
                    Text("切開位置")
                        .frame(width: 160, alignment: .leading)
                    Picker("", selection: $incisionSite) {
                        Text("選択してください").tag("選択してください")
                        Text("Axillary").tag("Axillary")
                        Text("Periareolar").tag("Periareolar")
                        Text("Inframammary Fold").tag("Inframammary Fold")
                    }
                    .frame(width: 200)
                }
                
                HStack {
                    Text("挿入層")
                        .frame(width: 160, alignment: .leading)
                    Picker("", selection: $insertionPlane) {
                        Text("選択してください").tag("選択してください")
                        Text("Subpectoral").tag("Subpectoral")
                        Text("Subglandular").tag("Subglandular")
                        Text("Dual Plane").tag("Dual Plane")
                    }
                    .frame(width: 200)
                }
                
                Divider().padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("備考")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var liposuctionSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("手術内容")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("吸引部位")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    ForEach(liposuctionAreas, id: \.category) { area in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(area.category)
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                            
                            ForEach(area.items, id: \.self) { item in
                                Toggle(item, isOn: Binding(
                                    get: { selectedLiposuctionAreas.contains(item) },
                                    set: { isSelected in
                                        if isSelected {
                                            selectedLiposuctionAreas.insert(item)
                                        } else {
                                            selectedLiposuctionAreas.remove(item)
                                        }
                                    }
                                ))
                                .toggleStyle(.checkbox)
                            }
                        }
                        .padding(.leading, 8)
                    }
                }
                .padding(.vertical, 8)
                
                Divider()
                
                HStack {
                    Text("吸引量(合計)")
                        .frame(width: 100, alignment: .leading)
                    TextField("cc", text: $liposuctionVolume)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 100)
                    Text("cc")
                }
                
                Toggle("Aquicell使用", isOn: $aquicellUsed)
                Toggle("Vaser使用", isOn: $vaserUsed)
                
                Divider().padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("備考")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var eyeSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("手術内容")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                Text("術式: \(eyeSurgeryType)")
                    .foregroundColor(.secondary)
                
                Divider().padding(.vertical, 8)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("備考")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextEditor(text: $notes)
                        .frame(height: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    private var otherSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 12) {
                Text("手術内容")
                    .font(.headline)
                    .padding(.bottom, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("備考")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    TextEditor(text: $notes)
                        .frame(height: 150)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .padding(.horizontal)
        .padding(.bottom)
    }
    
    // MARK: - 保存処理
    private func saveSurgery() {
        let newSurgery = Surgery(context: context)
        newSurgery.id = UUID()
        newSurgery.patient = patient
        newSurgery.surgeryDate = surgeryDate
        
        // ✅ 必須フィールドを設定
        newSurgery.createdDate = Date()
        
        // ✅ procedure（手術手技）を設定
        if surgeryCategory == "豊胸系" && surgeryType == "脂肪注入" {
            newSurgery.procedure = "\(surgeryType) (\(fatInjectionSubType))"
        } else if surgeryCategory == "目元系" {
            newSurgery.procedure = eyeSurgeryType
        } else if surgeryCategory == "脂肪吸引" {
            newSurgery.procedure = "\(surgeryCategory) - \(surgeryType)"
        } else {
            newSurgery.procedure = surgeryCategory
        }
        
        newSurgery.surgeryCategory = surgeryCategory
        
        if surgeryCategory == "豊胸系" {
            newSurgery.surgeryType = surgeryType
        } else if surgeryCategory == "目元系" {
            newSurgery.surgeryType = eyeSurgeryType
        } else if surgeryCategory == "脂肪吸引" {
            newSurgery.surgeryType = surgeryType
        }
        
        if surgeryCategory == "豊胸系" && surgeryType == "脂肪注入" {
            newSurgery.notes = "【種別】\(fatInjectionSubType)\n\n\(notes)"
        } else {
            newSurgery.notes = notes
        }
        
        if !heightCm.isEmpty, let height = Double(heightCm) {
            newSurgery.height = NSNumber(value: height)
        }
        if !bodyWeight.isEmpty, let weight = Double(bodyWeight) {
            newSurgery.bodyWeight = NSNumber(value: weight)
        }
        if !heightCm.isEmpty, !bodyWeight.isEmpty,
           let h = Double(heightCm), let w = Double(bodyWeight), h > 0 {
            let bmi = w / ((h / 100.0) * (h / 100.0))
            newSurgery.bmi = NSNumber(value: bmi)
        }
        
        if surgeryCategory == "豊胸系" {
            newSurgery.smokingHistory = smokingHistory
            newSurgery.breastfeedingHistory = breastfeedingHistory
            if let procNum = numberOfProcedures.prefix(1).compactMap({ Int(String($0)) }).first {
                newSurgery.numberOfProcedures = NSNumber(value: Int16(procNum))
            }
            
            if !nacImfRight.isEmpty, let nacR = Double(nacImfRight) {
                newSurgery.nacImfRight = NSNumber(value: nacR)
            }
            if !nacImfLeft.isEmpty, let nacL = Double(nacImfLeft) {
                newSurgery.nacImfLeft = NSNumber(value: nacL)
            }
            
            if !nacImfStretchRight.isEmpty, let stretchR = Double(nacImfStretchRight) {
                newSurgery.nacImfStretchRight = NSNumber(value: stretchR)
            }
            if !nacImfStretchLeft.isEmpty, let stretchL = Double(nacImfStretchLeft) {
                newSurgery.nacImfStretchLeft = NSNumber(value: stretchL)
            }
            
            if !skinThicknessRight.isEmpty, let skinR = Double(skinThicknessRight) {
                newSurgery.skinThicknessRight = NSNumber(value: skinR)
            }
            if !skinThicknessLeft.isEmpty, let skinL = Double(skinThicknessLeft) {
                newSurgery.skinThicknessLeft = NSNumber(value: skinL)
            }
        }
        
        if surgeryCategory == "豊胸系" && surgeryType == "脂肪注入" {
            newSurgery.donorSite = donorSite
            
            if !injectionVolumeR.isEmpty, let vol = Double(injectionVolumeR) {
                newSurgery.injectionVolumeR = NSNumber(value: vol)
            }
            if !injectionVolumeL.isEmpty, let vol = Double(injectionVolumeL) {
                newSurgery.injectionVolumeL = NSNumber(value: vol)
            }
            
            if !subcutaneousR.isEmpty, let sub = Double(subcutaneousR) {
                newSurgery.subcutaneousRight = NSNumber(value: sub)
            }
            if !subcutaneousL.isEmpty, let sub = Double(subcutaneousL) {
                newSurgery.subcutaneousLeft = NSNumber(value: sub)
            }
            
            if !subglandularR.isEmpty, let subg = Double(subglandularR) {
                newSurgery.subglandularRight = NSNumber(value: subg)
            }
            if !subglandularL.isEmpty, let subg = Double(subglandularL) {
                newSurgery.subglandularLeft = NSNumber(value: subg)
            }
            
            if !submuscularR.isEmpty, let subm = Double(submuscularR) {
                newSurgery.submuscularRight = NSNumber(value: subm)
            }
            if !submuscularL.isEmpty, let subm = Double(submuscularL) {
                newSurgery.submuscularLeft = NSNumber(value: subm)
            }
            
            if !decolleteR.isEmpty, let dec = Double(decolleteR) {
                newSurgery.decolletRight = NSNumber(value: dec)
            }
            if !decolleteL.isEmpty, let dec = Double(decolleteL) {
                newSurgery.decolletLeft = NSNumber(value: dec)
            }
            
            newSurgery.vaserUsed = NSNumber(value: vectraUsed)
            if vectraUsed {
                if !preOpVectraR.isEmpty, let vecR = Double(preOpVectraR) {
                    newSurgery.preOpVectraR = NSNumber(value: vecR)
                }
                if !preOpVectraL.isEmpty, let vecL = Double(preOpVectraL) {
                    newSurgery.preOpVectraL = NSNumber(value: vecL)
                }
            }
        }
        
        if surgeryCategory == "脂肪吸引" {
            let selectedAreasString = selectedLiposuctionAreas.sorted().joined(separator: ", ")
            newSurgery.donorSite = selectedAreasString
            
            if !liposuctionVolume.isEmpty, let lipo = Double(liposuctionVolume) {
                newSurgery.liposuctionVolume = NSNumber(value: lipo)
            }
            
            newSurgery.aquicellUsed = NSNumber(value: aquicellUsed)
            newSurgery.vaserUsed = NSNumber(value: vaserUsed)
        }
        
        if surgeryCategory == "豊胸系" && surgeryType == "シリコン" {
            if !implantSizeR.isEmpty, let implantR = Double(implantSizeR) {
                newSurgery.implantSizeR = NSNumber(value: implantR)
            }
            if !implantSizeL.isEmpty, let implantL = Double(implantSizeL) {
                newSurgery.implantSizeL = NSNumber(value: implantL)
            }
            
            if incisionSite != "選択してください" {
                newSurgery.incisionSite = incisionSite
            }
            if insertionPlane != "選択してください" {
                newSurgery.insertionPlane = insertionPlane
            }
        }
        
        print("🔍 保存前チェック:")
        print("  createdDate: \(String(describing: newSurgery.createdDate))")
        print("  procedure: \(String(describing: newSurgery.procedure))")
        
        do {
            try context.save()
            print("✅ Core Data保存成功")
            dismiss()
        } catch let error as NSError {
            print("❌ Core Data保存エラー: \(error)")
            errorMessage = "保存に失敗しました: \(error.localizedDescription)"
            showError = true
        }
    }
}
