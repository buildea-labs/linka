import SwiftUI
import MeasurementHistory
import GoogleMobileAds
import AudioToolbox
struct MainView: View {
    @StateObject private var viewModel = SpeedTestViewModel()
    @AppStorage("appAppearance") private var appAppearance: String = "system"
    @AppStorage("isPro") private var isPro: Bool = false
    @State private var detailsOpen: Bool = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var showOnboarding: Bool = false
    @State private var showSettings: Bool = false
    @State private var ringScale: CGFloat = 1.0
    @Namespace private var animation
    
    var colorScheme: ColorScheme? {
        if appAppearance == "light" { return .light }
        if appAppearance == "dark" { return .dark }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.surfacePage.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Safe Area Padding
                    Color.clear.frame(height: 80)
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
                            .scaleEffect(ringScale)
                            
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
                            MetricRing(
                                connecting: false,
                                progress: viewModel.progress,
                                value: String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ","),
                                unit: "Mbps",
                                size: 210,
                                animation: animation,
                                matchedId: "downloadValue"
                            )
                            .padding(.bottom, 24)
                            
                            Text("DOWNLOAD")
                                .font(.monoEyebrow)
                                .foregroundColor(.textSecondary)
                                .tracking(1.0)
                                .padding(.bottom, 8)
                            
                            HStack(spacing: 6) {
                                Text(String(format: "%.1f", viewModel.uploadSpeed).replacingOccurrences(of: ".", with: ","))
                                    .font(Font.system(size: 16, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                Text("Mbps upload")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                
                                Text("·")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                                    .padding(.horizontal, 4)
                                
                                Text("\(viewModel.ping)")
                                    .font(Font.system(size: 16, weight: .bold))
                                    .foregroundColor(.textPrimary)
                                Text("ms ping")
                                    .font(.bodySmall)
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(.bottom, 24)
                            
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
                            
                            // Último teste Glass Pill
                            NavigationLink(destination: HistoryView()) {
                                HStack {
                                    Text("Último teste")
                                        .font(.bodySmall.weight(.medium))
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                    
                                    Text(viewModel.lastTestSpeedString ?? "Nenhum teste anterior")
                                        .font(.monoCaption)
                                        .foregroundColor(.textSecondary)
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 10, weight: .semibold))
                                        .foregroundColor(.textSecondary)
                                }
                                .padding(.vertical, 12)
                                .padding(.horizontal, 16)
                                .background(.ultraThinMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                                .padding(.horizontal, 32)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 24)
                            
                            Spacer(minLength: 16)
                            
                            if !isPro {
                                BannerView(adSize: GADAdSizeLargeBanner)
                                    .frame(width: 320, height: 100)
                                    .padding(.vertical, 8)
                            }
                            
                            Spacer(minLength: 16)
                            
                            // Bottom Action Button
                            Button(action: {
                                detailsOpen = false
                                viewModel.startTest()
                            }) {
                                Text("Testar novamente")
                                    .font(Font.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color.surfacePage)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 18)
                                    .background(Color.textPrimary)
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 24)
                        }
                    }
                    
                    if viewModel.uiPhase != .done {
                        Spacer()
                    }
                }
            }
            .overlay(alignment: .topTrailing) {
                // Settings & History Glass Pills
                if viewModel.uiPhase == .idle || viewModel.uiPhase == .connecting || viewModel.uiPhase == .done {
                    HStack(spacing: 12) {
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
                    .padding(.top, 16)
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
                .preferredColorScheme(colorScheme)
        }
        .animation(LinkaMotion.spring, value: viewModel.uiPhase)
        .onChange(of: viewModel.uiPhase) { newPhase in
            if newPhase == .uploading {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                AudioServicesPlaySystemSound(1104) // Tick
                
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    ringScale = 1.05
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        ringScale = 1.0
                    }
                }
            } else if newPhase == .downloading || newPhase == .done {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    private var ringValue: String {
        switch viewModel.uiPhase {
        case .idle, .connecting:
            return "Preparando"
        case .downloading:
            return String(format: "%.1f", viewModel.downloadSpeed).replacingOccurrences(of: ".", with: ",")
        case .uploading, .done:
            return String(format: "%.1f", viewModel.uploadSpeed).replacingOccurrences(of: ".", with: ",")
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
