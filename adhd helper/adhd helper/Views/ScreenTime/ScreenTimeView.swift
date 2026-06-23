import SwiftUI

struct ScreenTimeView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @StateObject private var familyControlsManager = FamilyControlsManager.shared
    @State private var showAddLimitSheet = false
    @State private var showDeleteConfirmation = false
    @State private var limitToDelete: AppLimit? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background Gradient
                LinearGradient(
                    colors: [
                        Color(.systemGroupedBackground),
                        Color(.secondarySystemBackground)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Title Header with + Button
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("App Limits")
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                Text("Set daily limits to protect your focus")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            if familyControlsManager.isAuthorized {
                                Button(action: { showAddLimitSheet = true }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.indigo)
                                }
                            }
                        }
                        .padding(.horizontal, 4)
                        .padding(.top, 8)
                        
                        if !familyControlsManager.isAuthorized {
                            // Authorization Required Card
                            VStack(spacing: 16) {
                                Image(systemName: "hand.raised.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.indigo.opacity(0.8))
                                    .padding(.top, 20)
                                
                                Text("Screen Time Access Required")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Mindful Days requires Screen Time authorization to monitor device usage and enforce app block limits.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                
                                Button(action: {
                                    Task {
                                        await familyControlsManager.requestAuthorization()
                                    }
                                }) {
                                    Text("Authorize Screen Time")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 24)
                                        .padding(.vertical, 12)
                                        .background(Color.indigo)
                                        .clipShape(Capsule())
                                }
                                .padding(.bottom, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                            .onAppear {
                                Task {
                                    await familyControlsManager.requestAuthorization()
                                }
                            }
                        } else if viewModel.appLimits.isEmpty {
                            // Empty State Card
                            VStack(spacing: 16) {
                                Image(systemName: "hourglass.badge.plus")
                                    .font(.system(size: 50))
                                    .foregroundColor(.indigo.opacity(0.6))
                                    .padding(.top, 20)
                                
                                Text("No App Limits Yet")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(.primary)
                                
                                Text("Protect your focus by setting daily time allowances for distracting applications.")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                                
                                Button(action: { showAddLimitSheet = true }) {
                                    Text("Add App Limit")
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(.semibold)
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 10)
                                        .background(Color.indigo)
                                        .clipShape(Capsule())
                                }
                                .padding(.bottom, 20)
                            }
                            .frame(maxWidth: .infinity)
                            .background(Color(.secondarySystemGroupedBackground))
                            .cornerRadius(20)
                            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                        } else {
                            // Limits List
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(viewModel.appLimits) { limit in
                                    AppLimitRow(
                                        limit: limit,
                                        onToggle: {
                                            viewModel.toggleAppLimit(limit)
                                        }
                                    )
                                    .swipeToDelete {
                                        viewModel.triggerHapticFeedback()
                                        limitToDelete = limit
                                        showDeleteConfirmation = true
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            viewModel.triggerHapticFeedback()
                                            limitToDelete = limit
                                            showDeleteConfirmation = true
                                        } label: {
                                            Label("Delete Limit", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAddLimitSheet) {
                AddAppLimitSheet(viewModel: viewModel)
            }
            .confirmationDialog(
                "Delete App Limit",
                isPresented: $showDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete Limit", role: .destructive) {
                    if let limit = limitToDelete {
                        viewModel.deleteAppLimit(limit)
                    }
                }
                
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete this app limit?")
            }
        }
    }
}
