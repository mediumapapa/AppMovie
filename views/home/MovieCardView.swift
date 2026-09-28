import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    
    var body: some View {
        VStack(alignment: .center, spacing: 8) {
            // Contenedor del póster / ilustración
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardGray)
                
                // Aquí irá las imágenes cuando conectemos la API
                Image(systemName: movie.posterPath)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.black.opacity(0.6))
            }
            .frame(height: 120)
            .padding(.horizontal, 10)
            .padding(.top, 10)
            
            // Título
            Text(movie.title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal, 6)
            
            // Sinopsis
            Text(movie.overview)
                .font(.system(size: 11))
                .foregroundColor(.black.opacity(0.8))
                .multilineTextAlignment(.leading)
                .lineLimit(4)
                .padding(.horizontal, 10)
                .padding(.bottom, 12)
            
            Spacer(minLength: 0)
        }
        .frame(width: 170, height: 260)
        .background(Color.white)
        .overlay(
            RoundedRectangle(cornerRadius: 4)
                .stroke(Color.black, lineWidth: 1.8)
        )
    }
}

#Preview {
    MovieCardView(movie: Movie.samplePopular[0])
}
