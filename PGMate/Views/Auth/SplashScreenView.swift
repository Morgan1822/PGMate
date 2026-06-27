import SwiftUI

struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.6
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "#1A3566").ignoresSafeArea()

            VStack(spacing: 12) {
                Image("PGMateLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 28))
                    .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                Text("PGMate")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                    .opacity(textOpacity)

                Text("Smart PG Management")
                    .font(.subheadline)
                    .foregroundStyle(Color.gold)
                    .opacity(textOpacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }
            withAnimation(.easeIn(duration: 0.5).delay(0.4)) {
                textOpacity = 1.0
            }
        }
    }
}
