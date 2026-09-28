import SwiftUI

struct MovieDetail: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            // Tarjeta principal 
            VStack(alignment: .leading, spacing: 18) {
                // Tache rojo superior izquierdo para regresar al Home
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                }
                .padding(.top, 4)
                .padding(.leading, 4)
                
                // Título de la película
                Text(movie.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                
                // Portada / Ilustración de la película
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                    
                    Image(systemName: movie.posterPath)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 80, height: 80)
                        .foregroundColor(.black.opacity(0.6))
                }
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                
                // Sección Overview
                VStack(alignment: .leading, spacing: 10) {
                    Text("Overview")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.black)
                    
                    Text(movie.overview)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.black.opacity(0.85))
                        .lineSpacing(3)
                }
                .padding(.horizontal, 10)
                .padding(.bottom, 16)
                
                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color.appDetailBlue)
            .cornerRadius(32)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            
            // Botones de acción inferiores
            HStack(spacing: 36) {
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.system(size: 22, weight: .regular))
                        Text("Add Favorite")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(.black)
                }
                
                Button(action: {}) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 22, weight: .bold))
                        Text("Add List")
                            .font(.system(size: 17, weight: .medium))
                    }
                    .foregroundColor(.black)
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color.white.ignoresSafeArea())
    }
}

// Alias de conveniencia
typealias MovieDetailView = MovieDetail

#Preview {
    MovieDetail(movie: Movie.sampleMovies[0])
}
