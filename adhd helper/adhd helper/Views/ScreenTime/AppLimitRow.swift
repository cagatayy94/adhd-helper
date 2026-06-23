import SwiftUI
import FamilyControls

struct AppLimitRow: View {
    let limit: AppLimit
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            Text("⏳")
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(Color.indigo.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(limit.title)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(limit.isActive ? .primary : .secondary)
                
                HStack(spacing: 6) {
                    Text(selectionDescription)
                    Text("•")
                    Text("⏳ Max \(limit.threshold)")
                }
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { limit.isActive },
                set: { _ in onToggle() }
            ))
            .labelsHidden()
            .tint(.indigo)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(.separator), lineWidth: 1)
        )
    }
    
    private var selectionDescription: String {
        let appCount = limit.selection.applicationTokens.count
        let categoryCount = limit.selection.categoryTokens.count
        
        if appCount == 0 && categoryCount == 0 {
            return "No apps"
        } else if appCount > 0 && categoryCount == 0 {
            return "\(appCount) \(appCount == 1 ? "app" : "apps")"
        } else if appCount == 0 && categoryCount > 0 {
            return "\(categoryCount) \(categoryCount == 1 ? "category" : "categories")"
        } else {
            return "\(appCount)a, \(categoryCount)c"
        }
    }
}
