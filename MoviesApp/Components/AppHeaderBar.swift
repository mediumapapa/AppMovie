import SwiftUI

// Barra superior cyan que comparten Login, Home y Favoritos
struct AppHeaderBar<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        HStack {
            content
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.appCyan.ignoresSafeArea(edges: .top))
    }
}

// Título con la tipografía de la barra superior
struct AppHeaderTitle: View {
    let text: String
    var size: CGFloat = 26

    var body: some View {
        Text(text)
            .font(.system(size: size, weight: .heavy, design: .rounded))
            .foregroundColor(.black)
    }
}

#Preview {
    AppHeaderBar {
        AppHeaderTitle(text: "TMDB MOVIES")
        Spacer()
    }
}
