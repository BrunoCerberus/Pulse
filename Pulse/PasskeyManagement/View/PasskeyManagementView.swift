import EntropyCore
import SwiftUI

// MARK: - PasskeyManagementView

struct PasskeyManagementView: View {
    @StateObject private var viewModel: PasskeyManagementViewModel
    @State private var showError = false

    init(viewModel: PasskeyManagementViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if viewModel.viewState.passkeys.isEmpty && !viewModel.viewState.isLoading {
                    emptyState
                        .transition(.opacity)
                } else {
                    passkeysList
                        .transition(.opacity)
                }
            }
            .navigationTitle(Constants.title)
            .toolbar {
                if !viewModel.viewState.passkeys.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(Constants.registerButton) {
                            viewModel.handle(event: .registerPasskeyTapped)
                        }
                    }
                }
            }
            .onAppear { viewModel.handle(event: .onAppear) }
        }
        .alert(Constants.error, isPresented: $showError) {
            Button(Constants.okButton) {
                viewModel.handle(event: .onDismissError)
            }
        } message: {
            Text(viewModel.viewState.errorMessage ?? Constants.unknownError)
        }
        .onChange(of: viewModel.viewState.errorMessage) { _, newValue in
            showError = newValue != nil && !viewModel.viewState.isLoading
        }
    }

    private var passkeysList: some View {
        List {
            Section(Constants.accountLabel) {
                ForEach(viewModel.viewState.passkeys, id: \.self) { username in
                    Label(username, systemImage: "hand.raised.square.on.square")
                }
                .onDelete(perform: { indexSet in
                    viewModel.handle(event: .onDelete(indexSet: indexSet))
                })
            }
        }
        .listStyle(.plain)
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Image(systemName: "key.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text(Constants.noPasskeysTitle)
                .font(Typography.titleMedium)
                .foregroundStyle(.primary)

            Text(Constants.noPasskeysDescription)
                .font(Typography.bodyMedium)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button(Constants.registerButton) {
                viewModel.handle(event: .registerPasskeyTapped)
            }
            .buttonStyle(.glassProminent)
        }
        .padding(.horizontal, Spacing.xl)
    }
}

// MARK: - Constants & Events

extension PasskeyManagementView {
    enum Event {
        case registerPasskeyTapped
    }
}

#Preview {
    PasskeyManagementView(
        viewModel: PasskeyManagementViewModel(serviceLocator: .preview)
    )
}
