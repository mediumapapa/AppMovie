import SwiftUI

// Póster de una película. AsyncImage descarga la imagen de TMDB sin bloquear la pantalla.
// Mientras se descarga, o si la película no tiene póster, muestra un ícono.
struct MoviePosterView: View {
    let url: URL?
    var iconSize: CGFloat = 50

    var body: some View {
        AsyncImage(url: url) { image in
            image
                .resizable()
                .scaledToFit()
        } placeholder: {
            Image(systemName: "film")
                .resizable()
                .scaledToFit()
                .frame(width: iconSize, height: iconSize)
                .foregroundColor(.black.opacity(0.6))
        }
    }
}

#Preview {
    HStack {
        MoviePosterView(url: Movie.sampleMovies[0].posterURL)
        MoviePosterView(url: nil)
    }
    .frame(height: 200)
}
