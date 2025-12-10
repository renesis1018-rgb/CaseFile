//
//  FollowUpDetailView.swift
//  CaseFile
//
//  経過情報詳細画面
//

import SwiftUI
import CoreData

struct FollowUpDetailView: View {
    @ObservedObject var followUp: FollowUp
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 基本情報
                basicInfoSection
                
                Divider()
                
                // 経過測定値
                if shouldShowMeasurements {
                    measurementsSection
                }
            }
            .padding()
        }
        .navigationTitle("経過情報")
    }
    
    // MARK: - Computed
    
    private var shouldShowMeasurements: Bool {
        followUp.surgery?.surgeryCategory == "豊胸系"
    }
    
    // MARK: - Basic Info Section
    
    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("経過情報")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                if let date = followUp.followUpDate {
                    InfoRow(label: "観察日", value: formatDate(date))
                }
                
                if let timing = followUp.timing {
                    InfoRow(label: "経過時期", value: timing)
                }
                
                if let notes = followUp.notes, !notes.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("メモ")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Text(notes)
                            .font(.system(size: 13))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(nsColor: .controlBackgroundColor))
                            .cornerRadius(6)
                    }
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            .cornerRadius(10)
        }
    }
    
    // MARK: - Measurements Section
    
    private var measurementsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("経過測定値")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 8) {
                InfoRow(label: "Vectra経過(R)", value: followUp.postOpVectraR, unit: "cc")
                InfoRow(label: "Vectra経過(L)", value: followUp.postOpVectraL, unit: "cc")
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
        FollowUpDetailView(followUp: {
            let context = PersistenceController.preview.container.viewContext
            let followUp = FollowUp(context: context)
            followUp.followUpDate = Date()
            followUp.timing = "1M"
            followUp.notes = "順調に経過しています"
            return followUp
        }())
    }
    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
