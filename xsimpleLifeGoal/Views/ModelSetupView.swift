import SwiftUI

struct ModelSetupView: View {
    @Bindable var viewModel: ModelSetupViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text("Offline Model")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)

                    Text(viewModel.statusText)
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                }

                Text(viewModel.selectedModel.displayName)
                    .font(.headline)
                    .foregroundStyle(AppTheme.ink)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppTheme.card)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))

                VStack(spacing: 12) {
                    Button {
                        viewModel.useSmallModel()
                    } label: {
                        Label("Use Smaller Model", systemImage: "arrow.down.forward.and.arrow.up.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accent)
                    .disabled(viewModel.isDownloading)

                    Button {
                        Task {
                            do {
                                try await viewModel.downloadSelectedModel()
                            } catch {
                                // The view model owns user-facing download status.
                            }
                        }
                    } label: {
                        if viewModel.isDownloading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Label("Download Model", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .disabled(viewModel.isDownloading)

                    Button {
                        viewModel.continueWithoutModel()
                    } label: {
                        Label("Continue Without Model", systemImage: "arrow.forward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .tint(AppTheme.accent)
                    .disabled(viewModel.isDownloading)
                }
            }
            .padding()
            .frame(maxWidth: 420)
        }
    }
}

#Preview {
    ModelSetupView(viewModel: ModelSetupViewModel())
}
