import SwiftUI

/// Displays the result of an AI definition validation.
struct AIValidationCard: View {
    let result: ValidationResult

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Score header
            HStack(spacing: 10) {
                Image(systemName: result.grade.sfSymbol)
                    .font(.title3)
                    .foregroundStyle(gradeColor)
                VStack(alignment: .leading, spacing: 2) {
                    Text(result.grade.rawValue)
                        .font(.subheadline.bold())
                    Text("AI Quality Score: \(result.scorePercent)%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(gradeColor.opacity(0.2), lineWidth: 5)
                        .frame(width: 44, height: 44)
                    Circle()
                        .trim(from: 0, to: result.score)
                        .stroke(gradeColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 44, height: 44)
                        .animation(.easeInOut(duration: 0.6), value: result.score)
                    Text("\(result.scorePercent)")
                        .font(.caption2.bold())
                        .foregroundStyle(gradeColor)
                }
            }

            if !result.feedback.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(result.feedback, id: \.self) { item in
                        Label(item, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            if !result.suggestions.isEmpty {
                if !result.feedback.isEmpty { Divider() }
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(result.suggestions, id: \.self) { item in
                        Label(item, systemImage: "lightbulb.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }
        }
        .padding()
        .background(gradeColor.opacity(0.07))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var gradeColor: Color {
        switch result.grade {
        case .excellent:  return .green
        case .good:       return .blue
        case .fair:       return .orange
        case .needsWork:  return .red
        }
    }
}

#Preview {
    AIValidationCard(result: ValidationResult(
        score: 0.82,
        isValid: true,
        feedback: ["Good length — 22 words.", "Definition uses precise, academic language."],
        suggestions: []
    ))
    .padding()
}
