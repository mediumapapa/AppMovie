//
//  HomeView.swift
//  movies_app
//
//  

import SwiftUI

struct HomeView: View {
    @State private var viewModel: HomeViewModel

    init(viewModel: HomeViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Barra Superior (Header Cyan)
            headerBar

            // MARK: - Cuerpo Principal (Scroll)
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    // Buscador
                    searchBar
                        .padding(.top, 16)
                        .padding(.horizontal, 20)

                    if viewModel.isSearching {
                        // MARK: - Resultados de Búsqueda
                        searchResultsSection
                    } else {
                        // MARK: - Secciones del Home (populares y géneros)
                        ForEach(viewModel.sections) { section in
                            MovieSectionView(title: section.title, movies: section.movies)
                        }
                    }

                    Spacer(minLength: 30)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationDestination(for: Movie.self) { movie in
            MovieDetailView(viewModel: viewModel.makeMovieDetailViewModel(for: movie))
        }
        .alert("Cerrar Sesión", isPresented: $viewModel.showLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text("¿Estás seguro de que deseas salir de tu cuenta?")
        }
    }

    // Header Bar con botones de listas, favoritos y cuenta
    private var headerBar: some View {
        AppHeaderBar {
            AppHeaderTitle(text: "TMDB MOVIES")

            Spacer()

            HStack(spacing: 16) {
                // Botón de listas (para futuras listas personalizadas)
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }

                // Enlace a la pantalla de Favoritos
                NavigationLink(destination: FavoritesView(viewModel: viewModel.makeFavoritesViewModel())) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "heart")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)

                        // Indicador si hay favoritos guardados
                        if viewModel.hasFavorites {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 9, height: 9)
                                .offset(x: 2, y: -2)
                        }
                    }
                }

                // Menú de Perfil / Cerrar Sesión
                Menu {
                    if !viewModel.currentUser.isEmpty {
                        Text("Usuario: \(viewModel.currentUser)")
                    }

                    Button(role: .destructive) {
                        viewModel.requestLogout()
                    } label: {
                        Label("Cerrar Sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.black)
                }
            }
        }
    }

    // Buscador
    private var searchBar: some View {
        HStack(spacing: 14) {
            Text("Search")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.black)

            TextField("", text: $viewModel.searchText)
                .borderedField(cornerRadius: 20, height: 38)
        }
    }

    // Resultados de búsqueda en vivo
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Resultados para \"\(viewModel.searchText)\"")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)

            if viewModel.searchResults.isEmpty {
                Text("No se encontraron películas con ese nombre.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(viewModel.searchResults) { movie in
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
    NavigationStack {
        HomeView(
            viewModel: HomeViewModel(
                authStore: AuthStore(isLoggedIn: true, currentUser: "Demo"),
                favoritesStore: FavoritesStore(),
                service: MockMovieService()
            )
        )
    }
}
