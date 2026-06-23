import SwiftUI
import FamilyControls

struct AddAppLimitSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: CalendarViewModel
    
    @State private var title: String = ""
    @State private var selection = FamilyActivitySelection()
    @State private var isPickerPresented = false
    @State private var selectedThreshold: String = "30m"
    
    let thresholds = ["1m", "15m", "30m", "1h", "2h", "3h"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Limit Details")) {
                    TextField("Limit Title (e.g. Focus Hours)", text: $title)
                }
                
                Section(header: Text("Select Apps & Categories")) {
                    HStack {
                        Text("Selected Apps")
                        Spacer()
                        Button(action: { isPickerPresented = true }) {
                            Text(selectionText)
                                .foregroundColor(.indigo)
                        }
                    }
                }
                
                Section(header: Text("Time Limit Threshold")) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Daily limit allowance:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                            ForEach(thresholds, id: \.self) { thresh in
                                Text(thresh)
                                    .font(.system(.subheadline, design: .rounded))
                                    .fontWeight(.semibold)
                                    .foregroundColor(selectedThreshold == thresh ? .white : .primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(selectedThreshold == thresh ? Color.indigo : Color(.systemGroupedBackground))
                                    .clipShape(Capsule())
                                    .onTapGesture {
                                        viewModel.triggerHapticFeedback()
                                        selectedThreshold = thresh
                                    }
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .familyActivityPicker(isPresented: $isPickerPresented, selection: $selection)
            .navigationTitle("Add App Limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let finalTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "App Limit" : title
                        viewModel.addAppLimit(
                            title: finalTitle,
                            selection: selection,
                            threshold: selectedThreshold
                        )
                        dismiss()
                    }
                    .disabled(selection.applicationTokens.isEmpty && selection.categoryTokens.isEmpty)
                }
            }
        }
    }
    
    private var selectionText: String {
        let appCount = selection.applicationTokens.count
        let categoryCount = selection.categoryTokens.count
        if appCount == 0 && categoryCount == 0 {
            return "Choose..."
        } else {
            return "\(appCount) apps, \(categoryCount) cats"
        }
    }
}
