import Foundation

// 術式カテゴリ
enum SurgeryCategory: String, CaseIterable {
    case breastAugmentation = "豊胸"
    case liposuction = "脂肪吸引"
    case upperEyelid = "上眼瞼"
    case lowerEyelid = "下眼瞼"
    
    var displayName: String { rawValue }
}

// 術式タイプ
enum SurgeryType: String, CaseIterable {
    // 豊胸
    case fatGraft = "脂肪豊胸"
    case siliconeImplant = "シリコンバッグ豊胸"
    
    // 脂肪吸引
    case liposuctionArm = "脂肪吸引（上腕）"
    case liposuctionTorso = "脂肪吸引（体幹）"
    case liposuctionThigh = "脂肪吸引（大腿）"
    case liposuctionCalf = "脂肪吸引（下腿）"
    
    // 上眼瞼
    case doubleLidBurial = "二重埋没"
    case browLift = "眉毛下皮膚切除"
    case doubleLidIncision = "二重切開"
    
    // 下眼瞼
    case lowerLidDefatting = "脱脂"
    case transconjunctivalHamra = "裏ハムラ"
    case incisionalHamra = "切開ハムラ"
    
    var displayName: String { rawValue }
    
    var category: SurgeryCategory {
        switch self {
        case .fatGraft, .siliconeImplant:
            return .breastAugmentation
        case .liposuctionArm, .liposuctionTorso, .liposuctionThigh, .liposuctionCalf:
            return .liposuction
        case .doubleLidBurial, .browLift, .doubleLidIncision:
            return .upperEyelid
        case .lowerLidDefatting, .transconjunctivalHamra, .incisionalHamra:
            return .lowerEyelid
        }
    }
    
    // 術式ごとの写真角度
    var photoAngles: [String] {
        switch self.category {
        case .breastAugmentation, .upperEyelid, .lowerEyelid:
            // 5方向
            return ["正面", "右側面", "右斜め", "左斜め", "左側面"]
        case .liposuction:
            // 8方向
            return ["正面", "右側面", "右斜め", "左斜め", "左側面", "左斜め後ろ", "背面", "右斜め後ろ"]
        }
    }
    
    // カテゴリごとの術式を取得
    static func types(for category: SurgeryCategory) -> [SurgeryType] {
        return SurgeryType.allCases.filter { $0.category == category }
    }
}

// 術式ごとの固有データ（将来の拡張用）
protocol SurgerySpecificData {
    var surgeryType: SurgeryType { get }
}

// 脂肪豊胸の固有データ
struct FatGraftData: SurgerySpecificData {
    let surgeryType: SurgeryType = .fatGraft
    var vaserUsed: Bool
    var aquicellUsed: Bool
    var donorSite: String
    var injectionVolume: String
}

// シリコンバッグ豊胸の固有データ（将来実装）
struct SiliconeImplantData: SurgerySpecificData {
    let surgeryType: SurgeryType = .siliconeImplant
    var implantSize: String?
    var manufacturer: String?
    var insertionSite: String?
}

// 脂肪吸引の固有データ（将来実装）
struct LiposuctionData: SurgerySpecificData {
    let surgeryType: SurgeryType
    var aspirationSite: String?
    var aspirationVolume: String?
}
