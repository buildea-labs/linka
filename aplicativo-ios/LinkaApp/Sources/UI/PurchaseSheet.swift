import SwiftUI

struct PurchaseSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.linkaBackground.ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Image(systemName: "star.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.linkaAccent)
                        .padding(.top, 40)
                    
                    Text("Linka Pro")
                        .font(.linkaLargeTitle)
                        .foregroundColor(.linkaText)
                    
                    VStack(alignment: .leading, spacing: 20) {
                        FeatureRow(title: "Ad-free experience", icon: "xmark.shield.fill")
                        FeatureRow(title: "Detailed history maps", icon: "map.fill")
                        FeatureRow(title: "Custom server selection", icon: "server.rack")
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    Button(action: {
                        dismiss()
                    }) {
                        VStack {
                            Text("Upgrade for $4.99/mo")
                                .font(.linkaHeadline)
                            Text("Cancel anytime")
                                .font(.linkaCaption)
                        }
                        .foregroundColor(.linkaBackground)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.linkaAccent)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.linkaBackground, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.linkaTextSecondary)
                }
            }
        }
    }
}

struct FeatureRow: View {
    var title: String
    var icon: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(.linkaAccent)
                .frame(width: 24)
            Text(title)
                .font(.linkaBody)
                .foregroundColor(.linkaText)
        }
    }
}
