import SwiftUI

struct FavoritesView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: FavoritesViewModel

    // Cuadrícula de 2 columnas
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    init(viewModel: FavoritesViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Barra Superior con flecha de retroceso
            headerBar

            // MARK: - Contenido de Favoritos
            if viewModel.isEmpty {
                emptyStateView
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 18) {
                        ForEach(viewModel.favorites) { movie in
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

    private var headerBar: some View {
        AppHeaderBar {
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
            }

            Spacer()

            AppHeaderTitle(text: "FAVORITES", size: 24)

            Spacer()

            // Espaciador invisible para centrar el título
            Color.clear
                .frame(width: 22, height: 22)
        }
    }

    // Tarjeta con botón 'X' para eliminar y NavigationLink para ver el detalle
    private func favoriteCard(for movie: Movie) -> some View {
        ZStack(alignment: .topTrailing) {
            NavigationLink(value: movie) {
                MovieCardView(movie: movie, style: .compact)
            }
            .buttonStyle(PlainButtonStyle())

            Button(action: {
                withAnimation {
                    viewModel.remove(movie)
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
    NavigationStack {
        FavoritesView(viewModel: FavoritesViewModel(favoritesStore: FavoritesStore()))
    }
}
