import SwiftUI
import SwiftData

struct CategoriesView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: GlossaryViewModel
    @Query(sort: \GlossaryCategory.sortOrder) private var allCategories: [GlossaryCategory]

    @State private var isAddingCategory = false
    @State private var newCategoryName = ""
    @State private var newCategoryIcon = "book.closed.fill"
    @State private var newCategoryColor = "#5E6AD2"

    private var rootCategories: [GlossaryCategory] {
        viewModel.rootCategories(from: allCategories)
    }

    var body: some View {
        NavigationStack {
            Group {
                if rootCategories.isEmpty {
                    ContentUnavailableView(
                        "No Subjects Yet",
                        systemImage: "folder.badge.plus",
                        description: Text("Add a subject to start organising your glossary.")
                    )
                } else {
                    List {
                        ForEach(rootCategories) { category in
                            NavigationLink(destination: CategoryDetailView(category: category)) {
                                CategoryRow(
                                    category: category,
                                    subcategoryCount: viewModel.subcategories(of: category, from: allCategories).count
                                )
                            }
                        }
                        .onDelete(perform: deleteCategories)
                    }
                }
            }
            .navigationTitle("Subjects")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { isAddingCategory = true } label: {
                        Image(systemName: "folder.badge.plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .sheet(isPresented: $isAddingCategory) {
                addCategorySheet
            }
        }
    }

    private var addCategorySheet: some View {
        NavigationStack {
            Form {
                Section("Subject Details") {
                    TextField("Name (e.g. Biology)", text: $newCategoryName)
                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: newCategoryIcon)
                            .foregroundStyle(.blue)
                        TextField("SF Symbol", text: $newCategoryIcon)
                            .multilineTextAlignment(.trailing)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("New Subject")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isAddingCategory = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { saveCategory() }
                        .disabled(newCategoryName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveCategory() {
        let cat = GlossaryCategory(
            name: newCategoryName.trimmingCharacters(in: .whitespaces),
            icon: newCategoryIcon,
            colorHex: newCategoryColor,
            sortOrder: allCategories.count
        )
        modelContext.insert(cat)
        newCategoryName = ""
        newCategoryIcon = "book.closed.fill"
        isAddingCategory = false
    }

    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(rootCategories[index])
        }
    }
}

private struct CategoryRow: View {
    let category: GlossaryCategory
    let subcategoryCount: Int

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: category.colorHex).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: category.icon)
                    .foregroundStyle(Color(hex: category.colorHex))
                    .font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(category.name)
                    .font(.body.weight(.semibold))
                HStack(spacing: 6) {
                    Text("\(category.terms.count) terms")
                    if subcategoryCount > 0 {
                        Text("·")
                        Text("\(subcategoryCount) subcategories")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    CategoriesView()
        .environmentObject(GlossaryViewModel())
        .modelContainer(for: [Term.self, GlossaryCategory.self, TermRelationship.self],
                        inMemory: true)
}
