import SwiftUI

struct LinkaPlusWordmarkView: View {
    var height: CGFloat = 28

    var body: some View {
        Image("LinkaPlusWordmark")
            .resizable()
            .scaledToFit()
            .frame(height: height)
            .accessibilityLabel("Linka Plus")
    }
}
