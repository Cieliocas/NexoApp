import SwiftUI

struct CategoryCard: View {
    let category: GlossaryCategory
    let termCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: category.colorHex).opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: category.icon)
                        .foregroundStyle(Color(hex: category.colorHex))
                        .font(.system(size: 18))
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            Text(category.name)
                .font(.subheadline.bold())
                .lineLimit(2)
            Text(termCount == 1 ? "1 term" : "\(termCount) terms")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.04), radius: 4, y: 2)
    }
}
