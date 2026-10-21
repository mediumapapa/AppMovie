import SwiftUI

struct MovieDetailView: View {
    @Environment(\.dismiss) private var dismiss // Para cerrar la vista y regresar
    @State private var viewModel: MovieDetailViewModel

    init(viewModel: MovieDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Tarjeta principal
            VStack(alignment: .leading, spacing: 18) {
                // Tache rojo superior izquierdo para regresar
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
                Text(viewModel.movie.title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)

                // Portada / Ilustración de la película
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)

                    Image(systemName: viewModel.movie.posterPath)
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

                    Text(viewModel.movie.overview)
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
                Button(action: {
                    withAnimation {
                        viewModel.toggleFavorite()
                    }
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.favoriteIcon)
                            .font(.system(size: 22, weight: .regular))
                            .foregroundColor(viewModel.isFavorite ? .red : .black)

                        Text(viewModel.favoriteTitle)
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.black)
                    }
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
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    MovieDetailView(
        viewModel: MovieDetailViewModel(movie: Movie.sampleMovies[0], favoritesStore: FavoritesStore())
    )
}
