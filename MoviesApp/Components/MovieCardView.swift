import SwiftUI

// Tarjeta de película. Se usa en los carruseles del Home, en la búsqueda y en Favoritos.
struct MovieCardView: View {
    let movie: Movie
    var style: Style = .regular

    // regular: carruseles y búsqueda. compact: cuadrícula de favoritos.
    enum Style {
        case regular
        case compact
    }

    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Contenedor del póster (aquí irán las imágenes cuando conectemos la API)
            ZStack {
                RoundedRectangle(cornerRadius: isCompact ? 14 : 16)
                    .fill(Color.appCardGray)

                Image(systemName: movie.posterPath)
                    .resizable()
                    .scaledToFit()
                    .frame(width: isCompact ? 44 : 50, height: isCompact ? 44 : 50)
                    .foregroundColor(.black.opacity(0.6))
            }
            .frame(height: isCompact ? 110 : 120)
            .padding(.horizontal, isCompact ? 8 : 10)
            .padding(.top, isCompact ? 8 : 10)

            // Título
            Text(movie.title)
                .font(.system(size: isCompact ? 14 : 15, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 6)

            // Sinopsis
            Text(movie.overview)
                .font(.system(size: isCompact ? 10 : 11))
                .foregroundColor(.black.opacity(isCompact ? 0.75 : 0.8))
                .multilineTextAlignment(.leading)
                .lineLimit(isCompact ? 3 : 4)
                .padding(.horizontal, isCompact ? 8 : 10)
                .padding(.bottom, isCompact ? 10 : 12)

            Spacer(minLength: 0)
        }
        .frame(width: isCompact ? nil : 170, height: isCompact ? 240 : 260)
        .frame(maxWidth: isCompact ? .infinity : nil)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: isCompact ? 8 : 4)
                .stroke(Color.black, lineWidth: isCompact ? 1.6 : 1.8)
        )
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
