import SwiftUI

// Sección del Home: título y carrusel horizontal de películas.
// Al final del carrusel, si TMDB tiene más páginas, aparece la tarjeta "Ver más".
struct MovieSectionView: View {
    let title: String
    let movies: [Movie]
    var canLoadMore: Bool = false
    var isLoadingMore: Bool = false
    var onLoadMore: () -> Void = {}

    // Misma altura que MovieCardView, que también crece con el tamaño de letra
    @ScaledMetric(relativeTo: .body) private var cardHeight: CGFloat = 260

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Título de la sección
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .accessibilityAddTraits(.isHeader)

            // Carrusel horizontal de películas
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 14) {
                    ForEach(movies) { movie in
                        NavigationLink(value: movie) {
                            MovieCardView(movie: movie)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }

                    if canLoadMore {
                        loadMoreCard
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // Tarjeta del mismo tamaño que las películas para pedir la siguiente página
    private var loadMoreCard: some View {
        Button(action: onLoadMore) {
            VStack(spacing: 12) {
                if isLoadingMore {
                    ProgressView()
                        .controlSize(.large)
                } else {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 44))
                }
                Text(isLoadingMore ? "Cargando…" : "Ver más")
                    .font(.headline)
            }
            .foregroundColor(.black)
            .frame(width: 120, height: min(cardHeight, 520))
            .background(Color.appDetailBlue)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black, lineWidth: 1.8)
            )
        }
        .disabled(isLoadingMore)
        .accessibilityLabel("Ver más películas de \(title)")
    }
}

#Preview {
    NavigationStack {
        MovieSectionView(title: "Populares de la semana", movies: Movie.sampleMovies, canLoadMore: true)
    }
}
