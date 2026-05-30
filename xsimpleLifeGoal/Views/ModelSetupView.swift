import SwiftUI

struct ModelSetupView: View {
    @Bindable var viewModel: ModelSetupViewModel

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                        .fill(AppTheme.accentSoft)
                        .frame(width: 76, height: 76)
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 38, weight: .medium))
                        .foregroundStyle(AppTheme.accent)
                }
                .accessibilityHidden(true)

                VStack(spacing: 6) {
                    Text(AppStrings.key("modelSetup.title"))
                        .font(.title.weight(.semibold))
                        .foregroundStyle(AppTheme.ink)

                    Text(AppStrings.key("modelSetup.subtitle"))
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.center)

                    Text(viewModel.statusText)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(AppTheme.muted)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label(AppStrings.key("modelSetup.modelLabel"), systemImage: "cpu")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.muted)
                    Text(AppStrings.modelDisplayName(for: viewModel.selectedModel))
                        .font(.headline)
                        .foregroundStyle(AppTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(16)
                .background(AppTheme.card)
                .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous)
                        .stroke(AppTheme.border, lineWidth: 1)
                )
                .shadow(color: AppTheme.shadow, radius: 10, x: 0, y: 4)

                if viewModel.isDownloading {
                    VStack(spacing: 8) {
                        ProgressView(value: viewModel.downloadProgress ?? 0)
                            .tint(AppTheme.accent)
                        Text(viewModel.downloadProgressText)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(AppTheme.cardAlt)
                    .clipShape(RoundedRectangle(cornerRadius: AppTheme.radius, style: .continuous))
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(AppStrings.key("modelSetup.downloadProgress.accessibility"))
                    .accessibilityValue(viewModel.downloadProgressText)
                }

                VStack(spacing: 12) {
                    Button {
                        viewModel.useSmallModel()
                    } label: {
                        Label(AppStrings.key("modelSetup.useSmallerModel"), systemImage: "arrow.down.forward.and.arrow.up.backward")
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
                            Label(AppStrings.key("modelSetup.downloading"), systemImage: "hourglass")
                                .frame(maxWidth: .infinity)
                        } else {
                            Label(AppStrings.key("modelSetup.downloadModel"), systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(AppTheme.accent)
                    .disabled(viewModel.isDownloading)

                    Button {
                        viewModel.continueWithoutModel()
                    } label: {
                        Label(AppStrings.key("modelSetup.continueWithoutModel"), systemImage: "arrow.forward")
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
