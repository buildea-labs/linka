import SwiftUI

struct MainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @State private var detailsOpen: Bool = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showSettings: Bool = false
    @Namespace private var animation
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePage.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ZStack {
                        Image("wordmark")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 20)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 16)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    if viewModel.uiPhase != .done {
                        // Measuring UI
                        VStack(spacing: 0) {
                            MetricRing(
                                connecting: viewModel.uiPhase == .connecting || viewModel.uiPhase == .idle,
                                progress: viewModel.progress,
                                value: ringValue,
                                unit: (viewModel.uiPhase == .connecting || viewModel.uiPhase == .idle) ? nil : "Mbps",
                                size: 160,
                                animation: animation,
                                matchedId: "downloadValue"
                            )
                            
                            Text("LINKA SPEEDTEST")
                                .font(.monoEyebrow)
                                .foregroundColor(.textSecondary)
                                .tracking(1.0)
                                .padding(.top, 24)
                                .padding(.bottom, 12)
                            
                            Text(phaseLabel)
                                .font(.bodyRegular)
                                .foregroundColor(.textSecondary)
                                .padding(.bottom, 14)
                            
                            PhaseDots(
                                phases: [
                                    (key: "downloading", label: "Download"),
                                    (key: "uploading", label: "Upload")
                                ],
                                activeKey: activePhaseKey
                            )
                        }
                        // removed transition to allow fluid geometry effect
                    } else {
                        // Result UI
                        VStack(spacing: 0) {
                            HStack(spacing: 40) {
                                StatDisplay(
                                    label: "Download",
                                    value: String(format: "%.1f", viewModel.downloadSpeed),
                                    unit: "Mbps",
                                    accent: true,
                                    animation: animation,
                                    matchedId: "downloadValue"
                                )
                                
                                Rectangle()
                                    .fill(Color.borderDefault)
                                    .frame(width: 1, height: 64)
                                
                                StatDisplay(
                                    label: "Upload",
                                    value: String(format: "%.1f", viewModel.uploadSpeed),
                                    unit: "Mbps"
                                )
                            }
                            
                            Text("Sua conexão está pronta.")
                                .font(.displayTitle)
                                .foregroundColor(.textPrimary)
                                .padding(.top, 24)
                            
                            Button(action: {
                                withAnimation(LinkaMotion.spring) {
                                    detailsOpen.toggle()
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Text("Ver detalhes")
                                        .font(.bodySmall)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 10, weight: .semibold))
                                        .rotationEffect(.degrees(detailsOpen ? 180 : 0))
                                }
                                .foregroundColor(.textPrimary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.clear)
                            }
                            .padding(.top, 16)
                            
                            if detailsOpen {
                                DetailsDisclosure(
                                    operatorName: viewModel.networkType.isEmpty ? "--" : viewModel.networkType,
                                    provider: viewModel.provider.isEmpty ? "--" : viewModel.provider,
                                    duration: viewModel.testDuration.isEmpty ? "--" : viewModel.testDuration,
                                    ping: viewModel.ping
                                )
                                .padding(.top, 14)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                            }
                            
                            Button(action: {
                                detailsOpen = false
                                viewModel.startTest()
                            }) {
                                HStack(spacing: 6) {
                                    Text("Testar novamente")
                                        .font(.bodySmall)
                                    
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12, weight: .semibold))
                                }
                                .foregroundColor(.textPrimary)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(Color.clear)
                            }
                            .padding(.top, 14)
                            
                            // Ad Slot
                            VStack(spacing: 4) {
                                Text("Publicidade")
                                    .font(.monoCaption)
                                    .foregroundColor(.textSecondary)
                                
                                Text("320×50")
                                    .font(.monoCaption)
                                    .foregroundColor(.textSecondary)
                            }
                            .frame(width: 320, height: 50)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(Color.borderDefault, style: StrokeStyle(lineWidth: 1, dash: [4]))
                            )
                            .padding(.top, 28)
                        }
                        // removed transition to allow fluid geometry effect
                    }
                    
                    Spacer()
                }
                
                // Settings & History Glass Pills
                if viewModel.uiPhase == .idle || viewModel.uiPhase == .connecting || viewModel.uiPhase == .done {
                    VStack {
                        HStack(spacing: 12) {
                            Spacer()
                            
                            NavigationLink(destination: HistoryView()) {
                                Image(systemName: "clock")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            }
                            
                            Button(action: {
                                showSettings = true
                            }) {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.textPrimary)
                                    .frame(width: 40, height: 40)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.top, 54)
                        Spacer()
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            } else {
                viewModel.startTest()
            }
        }
        .onChange(of: showOnboarding) { newValue in
            if !newValue && !hasSeenOnboarding {
                hasSeenOnboarding = true
                viewModel.startTest()
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingSheet(isPresented: $showOnboarding)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet()
        }
        .animation(LinkaMotion.spring, value: viewModel.uiPhase)
    }
    
    private var ringValue: String {
        switch viewModel.uiPhase {
        case .idle, .connecting:
            return "Preparando"
        case .downloading:
            return String(format: "%.1f", viewModel.downloadSpeed)
        case .uploading, .done:
            return String(format: "%.1f", viewModel.uploadSpeed)
        }
    }
    
    private var phaseLabel: String {
        switch viewModel.uiPhase {
        case .idle, .connecting:
            return "Conectando ao servidor mais próximo…"
        case .downloading:
            return "Medindo velocidade de download…"
        case .uploading, .done:
            return "Medindo velocidade de upload…"
        }
    }
    
    private var activePhaseKey: String {
        switch viewModel.uiPhase {
        case .idle, .connecting:
            return ""
        case .downloading:
            return "downloading"
        case .uploading, .done:
            return "uploading"
        }
    }
}
