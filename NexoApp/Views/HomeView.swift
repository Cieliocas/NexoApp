import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var viewModel: GlossaryViewModel
    @Query(sort: \Term.createdAt, order: .reverse) private var recentTerms: [Term]
    @Query private var categories: [GlossaryCategory]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    heroSection
                    statsRow
                    if !recentTerms.isEmpty {
                        recentTermsSection
                    }
                    featuredCategoriesSection
                }
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Nexo")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.isAddingTerm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $viewModel.isAddingTerm) {
                AddTermView()
                    .environmentObject(viewModel)
            }
        }
    }

    // MARK: - Subviews

    private var heroSection: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [Color(.systemIndigo), Color(.systemBlue)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(alignment: .leading, spacing: 6) {
                Text("Your Academic Glossary")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Organised, connected, and validated by on-device AI.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            StatCard(value: recentTerms.count,  label: "Terms",      icon: "text.book.closed",  color: .blue)
            StatCard(value: rootCategories.count, label: "Subjects", icon: "folder.badge.gear", color: .indigo)
            let validated = recentTerms.filter { $0.isAIValidated }.count
            StatCard(value: validated, label: "AI Validated", icon: "cpu", color: .green)
        }
        .padding(.horizontal)
    }

    private var recentTermsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Recent Terms", icon: "clock")
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(recentTerms.prefix(10)) { term in
                        NavigationLink(destination: TermDetailView(term: term)) {
                            TermCard(term: term, style: .compact)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    private var featuredCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Browse by Subject", icon: "square.grid.2x2")
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(rootCategories) { category in
                    NavigationLink(destination: CategoryDetailView(category: category)) {
                        CategoryCard(category: category, termCount: category.terms.count)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    private var rootCategories: [GlossaryCategory] {
        viewModel.rootCategories(from: categories)
    }
}

// MARK: - Helper subviews

private struct StatCard: View {
    let value: Int
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text("\(value)")
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        Label(title, systemImage: icon)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

#Preview {
    HomeView()
        .environmentObject(GlossaryViewModel())
        .modelContainer(for: [Term.self, GlossaryCategory.self, TermRelationship.self],
                        inMemory: true)
}
