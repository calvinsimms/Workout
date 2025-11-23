//
//  CalculatorView.swift
//  Workout
//
//  Created by Calvin Simms on 2025-11-22.
//

import SwiftUI

struct CalculatorView: View {
    @State private var display: String = "0"
    @State private var expression: String = ""          // Stores full typed expression
    @State private var currentValue: Double = 0
    @State private var pendingOperation: String? = nil
    @State private var resetNext: Bool = false
    private let maxValue: Double = 999_999
    
    var body: some View {
        VStack {
            Grid {
                GridRow {
                    Text(expression.isEmpty ? display : expression)
                        .font(.system(size: 38))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .padding(.horizontal, 20)
                        .glassEffect()
                        .gridCellColumns(4)
                }
                
                GridRow {
                    calcButton("⌫") { backspace() }
                    calcButton("C") { clear() }
                    calcButton("%") { percent() }
                    calcButton("÷") { operation("÷") }
                }
                GridRow {
                    calcButton("7") { append("7") }
                    calcButton("8") { append("8") }
                    calcButton("9") { append("9") }
                    calcButton("×") { operation("×") }
                }
                GridRow {
                    calcButton("4") { append("4") }
                    calcButton("5") { append("5") }
                    calcButton("6") { append("6") }
                    calcButton("-") { operation("-") }
                }
                GridRow {
                    calcButton("1") { append("1") }
                    calcButton("2") { append("2") }
                    calcButton("3") { append("3") }
                    calcButton("+") { operation("+") }
                }
                GridRow {
                    calcButton("0") { append("0") }
                        .gridCellColumns(2)
                    calcButton(".") { append(".") }
                    calcButton("=") { equals() }
                }
            }
            .padding(.horizontal)
            Spacer()
        }
        .buttonStyle(.glass)
        .background(Color("Background"))
    }
    
    // MARK: - Button Functions
    private func append(_ value: String) {
        if resetNext {
            display = ""
            resetNext = false
        }
        
        if value == "." && display.contains(".") { return }

        let digitsOnly = display.replacingOccurrences(of: ".", with: "")
        if digitsOnly.count >= 6 && value != "." {
            return
        }

        if display == "0" && value != "." {
            display = value
        } else {
            display += value
        }
        
        expression += value
    }
    
    private func clear() {
        display = "0"
        expression = ""
        currentValue = 0
        pendingOperation = nil
    }
    
    private func backspace() {
        if resetNext { return }

        if !expression.isEmpty {
            expression.removeLast()
        }

        if !display.isEmpty {
            display.removeLast()
            if display.isEmpty { display = "0" }
        }
    }
    
    private func percent() {
        if let value = Double(display) {
            let result = value / 100
            display = format(result)
            expression = display
            resetNext = true
        }
    }
    
    private func operation(_ op: String) {

        if expression.isEmpty && display != "0" {
            expression = display
        }

        let trimmed = expression.trimmingCharacters(in: .whitespaces)

        if let lastChar = trimmed.last, "+-×÷".contains(lastChar) {
            var chars = Array(trimmed)
            while let last = chars.last, last == " " || "+-×÷".contains(last) {
                chars.removeLast()
            }
            expression = String(chars)
            expression += " \(op) "
            pendingOperation = op
            return
        }

        if let value = Double(display) {
            if let pending = pendingOperation {
                calculate(pending, value)
            } else {
                currentValue = value
            }
        }

        pendingOperation = op
        resetNext = true

        expression += " \(op) "
        
        display = ""
    }


    private func equals() {
        if let op = pendingOperation, let value = Double(display) {
            calculate(op, value)
            pendingOperation = nil
        }

        expression = ""
        
        resetNext = true
    }
    
    private func calculate(_ op: String, _ value: Double) {

        switch op {
        case "+": currentValue += value
        case "-": currentValue -= value
        case "×": currentValue *= value
        case "÷":
            if value == 0 {
                display = "Error"
                expression = ""
                currentValue = 0
                pendingOperation = nil
                resetNext = true
                return
            }
            currentValue /= value
        default: break
        }

        currentValue = clamp(currentValue)
        display = format(currentValue)
    }

    private func applyPercentage(_ pct: Double) {
        if let value = Double(display) {
            let result = value * pct
            display = format(result)
            expression = display
            resetNext = true
        }
    }
    
    private func format(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(value))
        } else {
            return String(format: "%.2f", value)
        }
    }
    
    private func calcButton(_ title: String, width: CGFloat = 60, color: Color = .clear, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.title2)
                .frame(maxWidth: .infinity, maxHeight: 40)
                .foregroundColor(.primary)
                .cornerRadius(10)
        }
    }
    
    private func clamp(_ value: Double) -> Double {
        if value > maxValue { return maxValue }
        if value < -maxValue { return -maxValue }
        return value
    }
}

#Preview {
    CalculatorView()
}
