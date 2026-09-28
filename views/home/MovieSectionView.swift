import SwiftUI

struct MovieSectionView: View {
    let title: String
    let movies: [Movie]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // Título de la sección y flechas de navegación
            HStack {
                Text(title)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)
                
                Spacer()
                
                // Flechas de navegación (izquierda y derecha)
                HStack(spacing: 8) {
                    Image(systemName: "arrowtriangle.backward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                    
                    Image(systemName: "arrowtriangle.forward.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 20)
            
            // Carrusel horizontal de películas
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(movies) { movie in
                        MovieCardView(movie: movie)
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
