import SwiftUI

struct MovieDetailView: View {
    @Environment(\.dismiss) private var dismiss // Para cerrar la vista y regresar
    @State private var viewModel: MovieDetailViewModel

    init(viewModel: MovieDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        // ScrollView: una sinopsis larga o una letra grande no se cortan en teléfonos pequeños
        ScrollView(.vertical) {
            // Tarjeta principal
            VStack(alignment: .leading, spacing: 18) {
                // Tache rojo superior izquierdo para regresar
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44, alignment: .leading)
                }
                .accessibilityLabel("Regresar")

                // Título de la película
                Text(viewModel.movie.title)
                    .font(.title2.weight(.bold))
                    .foregroundColor(.black)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 8)
                    .accessibilityAddTraits(.isHeader)

                // Portada de la película
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)

                    MoviePosterView(url: viewModel.movie.posterURL, iconSize: 80)
                        .padding(10)
                }
                .frame(height: 300)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 10)
                .accessibilityHidden(true)

                // Sinopsis de TMDB
                textSection(
                    title: "Sinopsis",
                    text: viewModel.movie.overview.isEmpty
                        ? "TMDB no tiene sinopsis en español para esta película."
                        : viewModel.movie.overview
                )

                // Nota personal que el usuario escribió al guardarla en una lista
                if !viewModel.personalNote.isEmpty {
                    textSection(title: "Tu nota", text: viewModel.personalNote)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity)
            .background(Color.appDetailBlue)
            .cornerRadius(32)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 20)
        }
        // Botones de acción fijos en la parte inferior
        .safeAreaInset(edge: .bottom) {
            actionButtons
        }
        .background(Color.white.ignoresSafeArea())
        .navigationBarBackButtonHidden(true)
        .onAppear {
            viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showAddToList, onDismiss: viewModel.refresh) {
            AddToListSheet(viewModel: viewModel.makeAddToListViewModel())
        }
    }

    private func textSection(title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.black)
                .accessibilityAddTraits(.isHeader)

            Text(text)
                .font(.body)
                .foregroundColor(.black.opacity(0.85))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 10)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            actionButton(
                icon: viewModel.favoriteIcon,
                iconColor: viewModel.isFavorite ? .red : .black,
                title: viewModel.favoriteTitle
            ) {
                withAnimation {
                    viewModel.toggleFavorite()
                }
            }

            actionButton(icon: viewModel.listIcon, iconColor: .black, title: viewModel.listTitle) {
                viewModel.showAddToList = true
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.white)
    }

    private func actionButton(icon: String, iconColor: Color, title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)

                Text(title)
                    .font(.headline)
                    .foregroundColor(.black)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity, minHeight: 48)
            .background(Color.white)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.black, lineWidth: 1.6)
            )
        }
    }
}

#Preview {
    MovieDetailView(
        viewModel: MovieDetailViewModel(
            movie: Movie.sampleMovies[1],
            favoritesService: MockFavoritesService(),
            listsService: MockListsService.sample
        )
    )
}
