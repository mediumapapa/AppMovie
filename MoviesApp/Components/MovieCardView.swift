import SwiftUI

// Tarjeta de película. Se usa en los carruseles del Home, en la búsqueda y en Favoritos.
struct MovieCardView: View {
    let movie: Movie
    var style: Style = .regular

    // Medidas de la tarjeta que crecen con el tamaño de letra del iPhone,
    // para que el título y la sinopsis no se corten con letra grande
    @ScaledMetric(relativeTo: .body) private var regularWidth: CGFloat = 170
    @ScaledMetric(relativeTo: .body) private var regularHeight: CGFloat = 260
    @ScaledMetric(relativeTo: .body) private var compactHeight: CGFloat = 240

    // regular: carruseles. compact: cuadrículas de búsqueda y favoritos.
    enum Style {
        case regular
        case compact
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Contenedor del póster (la imagen llega de TMDB)
            ZStack {
                RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                    .fill(Color.appCardGray)

                MoviePosterView(url: movie.posterURL, iconSize: isCompact ? 44 : 50)
                    .padding(6)
            }
            .frame(height: isCompact ? 110 : 120)
            .padding(.horizontal, isCompact ? 8 : 10)
            .padding(.top, isCompact ? 8 : 10)

            // Título
            Text(movie.title)
                .font(.subheadline.weight(.bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 6)

            // Sinopsis
            Text(movie.overview)
                .font(.caption)
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineLimit(isCompact ? 3 : 4)
                .padding(.horizontal, isCompact ? 8 : 10)
                .padding(.bottom, isCompact ? 10 : 12)

            Spacer(minLength: 0)
        }
        .frame(width: isCompact ? nil : min(regularWidth, 300), height: min(isCompact ? compactHeight : regularHeight, 520))
        .frame(maxWidth: isCompact ? .infinity : nil)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 8 : 4)
                .stroke(Color.black, lineWidth: isCompact ? 1.6 : 1.8)
        )
        // VoiceOver lee la tarjeta como un solo elemento: título y sinopsis
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(movie.title)
        .accessibilityHint(movie.overview)
    }

    private var isCompact: Bool {
        style == .compact
    }
}

#Preview {
    HStack {
        MovieCardView(movie: Movie.sampleMovies[0])
        MovieCardView(movie: Movie.sampleMovies[1], style: .compact)
    }
}
