import SwiftUI

struct FavoritesView: View {
    @Environment(FavoritesStore.self) private var favoritesStore
    @Environment(\.dismiss) private var dismiss
    
    // Configuración de cuadrícula de 2 columnas
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Barra Superior (Header Cyan con flecha de retroceso)
            headerBar
            
            // MARK: - Contenido de Favoritos
            if favoritesStore.favorites.isEmpty {
                emptyStateView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(favoritesStore.favorites) { movie in
                            favoriteCard(for: movie)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
    }
    
    // Header Bar con botón de retroceso a la izquierda
    private var headerBar: some View {
        HStack {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            Text("FAVORITES")
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
            
            Spacer()
            
            // Espaciador invisible para centrar el título
            Color.clear
                .frame(width: 22, height: 22)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.appCyan.ignoresSafeArea(edges: .top))
    }
    
    // Tarjeta con botón 'X' para eliminar y NavigationLink para ver detalle
    private func favoriteCard(for movie: Movie) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: movie) {
                VStack(alignment: .center, spacing: 8) {
                    // Contenedor del póster
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.appCardGray)
                        
                        Image(systemName: movie.posterPath)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 44, height: 44)
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .frame(height: 110)
                    .padding(.horizontal, 8)
                    .padding(.top, 8)
                    
                    // Título
                    Text(movie.title)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .padding(.horizontal, 6)
                    
                    // Sinopsis corta
                    Text(movie.overview)
                        .font(.system(size: 10))
                        .foregroundColor(.black.opacity(0.75))
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                        .padding(.horizontal, 8)
                        .padding(.bottom, 10)
                    
                    Spacer(minLength: 0)
                }
                .frame(height: 240)
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.black, lineWidth: 1.6)
                )
            }
            .buttonStyle(PlainButtonStyle())
            
            // Botón "X" en la esquina superior derecha para eliminar de favoritos
            Button(action: {
                withAnimation {
                    favoritesStore.remove(movie)
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.red)
                    .background(Color.white.clipShape(Circle()))
            }
            .padding(6)
        }
    }
    
    // Vista vacía cuando no hay favoritos
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "heart.slash")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(.gray)
            
            Text("No tienes favoritos aún")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
            
            Text("Toca el botón de corazón en el detalle de cualquier película para añadirla a tu lista de favoritos.")
                .font(.system(size: 14))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    FavoritesView()
        .environment(FavoritesStore())
}
