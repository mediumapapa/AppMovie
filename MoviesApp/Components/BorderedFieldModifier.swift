import SwiftUI

// Estilo de los campos de texto con borde negro (buscador y login)
struct BorderedFieldModifier: ViewModifier {
    var cornerRadius: CGFloat
    var height: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 14)
            .frame(height: height)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.black, lineWidth: 1.8)
            )
    }
}

extension View {
    func borderedField(cornerRadius: CGFloat = 14, height: CGFloat = 44) -> some View {
        modifier(BorderedFieldModifier(cornerRadius: cornerRadius, height: height))
    }
}
