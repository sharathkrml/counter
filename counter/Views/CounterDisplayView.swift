//
//  CounterDisplayView.swift
//  counter
//

import SwiftUI

struct CounterDisplayView: View {
    let count: Int

    var body: some View {
        Text("\(count)")
            .font(.system(size: 72, weight: .bold, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
    }
}

#Preview {
    CounterDisplayView(count: 42)
}
