import SwiftUI

struct MovieSectionView: View {
    let title: String
    let movies: [Movie]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Título de la sección
            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            // Carrusel horizontal de películas
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(movies) { movie in
                        NavigationLink(value: movie) {
                            MovieCardView(movie: movie)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

#Preview {
    MovieSectionView(title: "Popular this week", movies: Movie.sampleMovies)
}
