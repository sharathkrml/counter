//
//  ContentView.swift
//  counter
//

import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = CounterViewModel()

    var body: some View {
        VStack(spacing: 24) {
            Text("Counter")
                .font(.title2.weight(.semibold))

            switch viewModel.status {
            case .ready:
                CounterDisplayView(count: viewModel.count)

                HStack(spacing: 16) {
                    Button {
                        Task { await viewModel.decrement() }
                    } label: {
                        Image(systemName: "minus")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.bordered)

                    Button("Reset") {
                        Task { await viewModel.reset() }
                    }
                    .buttonStyle(.bordered)

                    Button {
                        Task { await viewModel.increment() }
                    } label: {
                        Image(systemName: "plus")
                            .frame(width: 44, height: 44)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

            case .failed(let message):
                Text("Backend failed")
                    .font(.headline)
                Text(message)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .multilineTextAlignment(.center)

            case .starting, .stopped:
                ProgressView("Starting backend…")
            }

        }
        .padding(40)
        .frame(minWidth: 320, minHeight: 260)
        .task {
            await viewModel.start()
        }
    }
}

#Preview {
    ContentView()
}
