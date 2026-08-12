import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.linkaBackground
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    MetricRing(
                        progress: viewModel.progress,
                        isTesting: viewModel.isTesting,
                        phase: viewModel.uiPhase,
                        displaySpeed: viewModel.uiPhase == .uploading ? viewModel.uploadSpeed : viewModel.downloadSpeed
                    )
                    
                    HStack(spacing: 24) {
                        MetricItem(title: "Ping", value: viewModel.ping > 0 ? "\(viewModel.ping) ms" : "--", icon: "network", color: .linkaTextSecondary)
                        MetricItem(title: "Download", value: viewModel.downloadSpeed > 0 ? String(format: "%.1f", viewModel.downloadSpeed) : "--", icon: "arrow.down.circle.fill", color: .linkaSecondary)
                        MetricItem(title: "Upload", value: viewModel.uploadSpeed > 0 ? String(format: "%.1f", viewModel.uploadSpeed) : "--", icon: "arrow.up.circle.fill", color: .linkaPrimary)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                    
                    Button(action: {
                        if viewModel.isTesting {
                            viewModel.stopTest()
                        } else {
                            viewModel.startTest()
                        }
                    }) {
                        Text(viewModel.isTesting ? "STOP" : "GO")
                            .font(.linkaTitle)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 120)
                            .background(
                                Circle()
                                    .fill(viewModel.isTesting ? Color.red : Color.linkaPrimary)
                            )
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Linka")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.linkaBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { viewModel.showSettings = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.linkaText)
                    }
                    .accessibilityLabel("Configurações")
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { viewModel.showPurchase = true }) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.linkaAccent)
                    }
                    .accessibilityLabel("Linka Pro")
                }
            }
            .sheet(isPresented: $viewModel.showSettings) {
                SettingsSheet()
            }
            .sheet(isPresented: $viewModel.showPurchase) {
                PurchaseSheet()
            }
            .sheet(isPresented: $viewModel.showOnboarding) {
                OnboardingSheet(isPresented: $viewModel.showOnboarding)
            }
        }
    }
}

struct MetricItem: View {
    var title: String
    var value: String
    var icon: String
    var color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)
                Text(title)
                    .font(.linkaCaption)
                    .foregroundColor(.linkaTextSecondary)
            }
            
            Text(value)
                .font(.linkaHeadline)
                .foregroundColor(.linkaText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.linkaSurface)
        .cornerRadius(16)
    }
}
