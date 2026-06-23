//
//  ContentView.swift
//  adhd helper
//
//  Created by Çağatay Yılmaz on 28.05.2026.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: viewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)
            
            ScreenTimeView(viewModel: viewModel)
                .tabItem {
                    Label("Screen Time", systemImage: "hourglass")
                }
                .tag(1)
        }
        .accentColor(.indigo)
    }
}

#Preview {
    ContentView()
}
