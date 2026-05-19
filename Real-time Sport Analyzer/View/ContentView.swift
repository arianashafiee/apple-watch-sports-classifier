//
//  ContentView.swift
//  Real-time Sport Analyzer
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "figure.run")
                .font(.largeTitle)
            Text("Real-time Sport Analyzer")
                .font(.headline)
            Text("Companion app for watch data collection")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
