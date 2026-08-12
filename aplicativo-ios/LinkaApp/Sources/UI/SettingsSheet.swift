import SwiftUI

struct SettingsSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var serverSelection = "Automatic (Cloudflare)"
    @State private var hapticFeedback = true
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("TESTING PREFERENCES").font(.linkaCaption)) {
                    Picker("Server", selection: $serverSelection) {
                        Text("Automatic (Cloudflare)").tag("Automatic (Cloudflare)")
                    }
                    Toggle("Haptic Feedback", isOn: $hapticFeedback)
                }
                .listRowBackground(Color.linkaSurface)
                .foregroundColor(.linkaText)
                
                Section(header: Text("ABOUT").font(.linkaCaption)) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.linkaTextSecondary)
                    }
                }
                .listRowBackground(Color.linkaSurface)
                .foregroundColor(.linkaText)
            }
            .scrollContentBackground(.hidden)
            .background(Color.linkaBackground.ignoresSafeArea())
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.linkaBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.linkaPrimary)
                    .font(.linkaHeadline)
                }
            }
        }
    }
}
