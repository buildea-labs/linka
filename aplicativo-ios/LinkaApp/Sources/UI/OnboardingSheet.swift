import SwiftUI

struct OnboardingSheet: View {
    @Binding var isPresented: Bool
    @State private var step: Int = 0
    
    var body: some View {
        ZStack {
            Color.surfacePage.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                if step == 0 {
                    OnboardingStepOne()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    OnboardingStepTwo()
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                }
                
                Spacer()
                
                VStack(spacing: 14) {
                    PhaseDots(
                        phases: [
                            (key: "0", label: ""),
                            (key: "1", label: "")
                        ],
                        activeKey: "\(step)"
                    )
                    
                    Button(action: {
                        withAnimation(LinkaMotion.spring) {
                            if step == 0 {
                                step = 1
                            } else {
                                isPresented = false
                            }
                        }
                    }) {
                        Text(step == 0 ? "Continuar" : "Permitir e começar")
                            .font(.bodyRegular.weight(.bold))
                            .foregroundColor(.brandOnSurface)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.brandSurface)
                            .cornerRadius(14)
                    }
                    
                    if step == 1 {
                        Button(action: {
                            isPresented = false
                        }) {
                            Text("Agora não")
                                .font(.bodySmall)
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 26)
            }
        }
    }
}

struct OnboardingStepOne: View {
    var body: some View {
        VStack(spacing: 0) {
            // Hero Gauge
            ZStack {
                Circle()
                    .stroke(Color.textSecondary.opacity(0.12), lineWidth: 3)
                    .frame(width: 172, height: 172)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(Color.brandSurface, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 172, height: 172)
                    .rotationEffect(.degrees(-90))
                
                VStack(spacing: 4) {
                    Text("184,3")
                        .font(.system(size: 40, weight: .semibold, design: .monospaced))
                        .foregroundColor(.textPrimary)
                    Text("Mbps")
                        .font(.monoCaption)
                        .foregroundColor(.textSecondary)
                }
            }
            .frame(width: 176, height: 176)
            
            // Chips
            HStack(spacing: 10) {
                OnboardingChip(label: "Download", icon: "arrow.down", active: true)
                OnboardingChip(label: "Upload", icon: "arrow.up", active: false)
            }
            .padding(.top, 26)
            
            Text("Abriu, mediu.")
                .font(.displayTitle)
                .foregroundColor(.textPrimary)
                .padding(.top, 26)
            
            Text("Sem botão para apertar.")
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
                .padding(.top, 6)
        }
    }
}

struct OnboardingChip: View {
    var label: String
    var icon: String
    var active: Bool
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(active ? .brandSurface : .textSecondary)
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color.textSecondary.opacity(0.1))
        .clipShape(Capsule())
    }
}

struct OnboardingStepTwo: View {
    var body: some View {
        VStack(spacing: 0) {
            Text("Três permissões.")
                .font(.displayTitle)
                .foregroundColor(.textPrimary)
            
            Text("Você pode revisar depois nos Ajustes.")
                .font(.bodyRegular)
                .foregroundColor(.textSecondary)
                .padding(.top, 6)
            
            VStack(spacing: 0) {
                PermissionRow(
                    icon: "network", 
                    color: .brandSurface,
                    title: "Rede local", 
                    desc: "Encontra o servidor mais próximo para medir sem desvio."
                )
                Divider().background(Color.textSecondary.opacity(0.14))
                PermissionRow(
                    icon: "bell.fill", 
                    color: .brandSurface,
                    title: "Notificações", 
                    desc: "Avisa quando a medição termina em segundo plano."
                )
                Divider().background(Color.textSecondary.opacity(0.14))
                PermissionRow(
                    icon: "location.fill", 
                    color: Color.gray,
                    title: "Rastreamento (opcional)", 
                    desc: "Mantém o app gratuito com anúncios relevantes. Recusar não bloqueia nada."
                )
            }
            .padding(.horizontal, 16)
            .background(Color.textSecondary.opacity(0.05))
            .cornerRadius(14)
            .padding(.horizontal, 24)
            .padding(.top, 26)
        }
    }
}

struct PermissionRow: View {
    var icon: String
    var color: Color
    var title: String
    var desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color)
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.bodySmall.weight(.semibold))
                    .foregroundColor(.textPrimary)
                Text(desc)
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 14)
    }
}
