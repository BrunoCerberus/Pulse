import SwiftUI

struct CreateCollectionSheet: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var description: String = ""
    @FocusState private var focusedField: Field?

    let onCreate: (String, String) -> Void

    private enum Field {
        case name
        case description
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient.subtleBackground
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: Spacing.lg) {
                        iconSection

                        formSection

                        tipSection
                    }
                    .padding(Spacing.lg)
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        HapticManager.shared.tap()
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        HapticManager.shared.success()
                        onCreate(
                            name.trimmingCharacters(in: .whitespacesAndNewlines),
                            description.trimmingCharacters(in: .whitespacesAndNewlines)
                        )
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                focusedField = .name
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(Color.Semantic.info.opacity(0.15))
                .frame(width: 80, height: 80)

            Image(systemName: "folder.badge.plus")
                .font(.system(size: 32))
                .foregroundStyle(Color.Semantic.info)
        }
    }

    private var formSection: some View {
        VStack(spacing: Spacing.md) {
            GlassCard(style: .thin, shadowStyle: .subtle, padding: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Name")
                        .font(Typography.labelMedium)
                        .foregroundStyle(.secondary)

                    TextField("e.g., Research Notes", text: $name)
                        .font(Typography.bodyLarge)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .description
                        }
                }
            }

            GlassCard(style: .thin, shadowStyle: .subtle, padding: Spacing.md) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Text("Description (optional)")
                        .font(Typography.labelMedium)
                        .foregroundStyle(.secondary)

                    TextField("What is this collection about?", text: $description, axis: .vertical)
                        .font(Typography.bodyLarge)
                        .lineLimit(3 ... 5)
                        .focused($focusedField, equals: .description)
                        .submitLabel(.done)
                        .onSubmit {
                            if isValid {
                                HapticManager.shared.success()
                                onCreate(
                                    name.trimmingCharacters(in: .whitespacesAndNewlines),
                                    description.trimmingCharacters(in: .whitespacesAndNewlines)
                                )
                            }
                        }
                }
            }
        }
    }

    private var tipSection: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: IconSize.sm))
                .foregroundStyle(Color.Accent.gold)

            Text("Tip: Add articles to your collection from the article detail screen.")
                .font(Typography.captionLarge)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .background(Color.Accent.gold.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: CornerRadius.md))
    }
}

#Preview {
    CreateCollectionSheet { name, description in
        print("Created: \(name) - \(description)")
    }
}
