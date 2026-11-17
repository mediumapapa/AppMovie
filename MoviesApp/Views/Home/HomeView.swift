//
//  HomeView.swift
//  movies_app
//

import SwiftUI

// Pantallas a las que se llega desde la barra superior del Home.
// Toda la navegación es por valor (NavigationLink(value:)) para no desfasar el NavigationStack.
enum AppRoute: Hashable {
    case favorites
    case lists
}

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
                        // MARK: - Resultados de Búsqueda (TMDB /search/movie)
                        searchResultsSection
                    } else {
                        // MARK: - Contenido según el estado de la consulta a TMDB
                        switch viewModel.state {
                        case .loading:
                            loadingView("Cargando películas…")

                        case .content(let sections):
                            // Secciones del Home (populares y géneros)
                            ForEach(sections) { section in
                                MovieSectionView(
                                    title: section.title,
                                    movies: section.movies,
                                    canLoadMore: section.canLoadMore,
                                    isLoadingMore: viewModel.loadingMoreSectionIDs.contains(section.id)
                                ) {
                                    Task {
                                        await viewModel.loadMore(in: section.id)
                                    }
                                }
                            }

                        case .empty:
                            messageView(
                                icon: "film",
                                title: "No hay películas por ahora",
                                message: "TMDB no regresó películas para mostrar.",
                                buttonTitle: "Actualizar"
                            ) {
                                await viewModel.loadMovies()
                            }

                        case .error(let message):
                            messageView(
                                icon: "exclamationmark.triangle",
                                title: "No se pudieron cargar las películas",
                                message: message,
                                buttonTitle: "Reintentar"
                            ) {
                                await viewModel.loadMovies()
                            }
                        }
                    }

                    Spacer(minLength: 30)
                }
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.white.ignoresSafeArea())
        // Al aparecer (y al regresar del detalle o de Favoritos) revisa si hay favoritos para el punto rojo
        .onAppear {
            viewModel.refreshFavorites()
        }
        // Pide las películas a TMDB cuando aparece el Home. .task espera la respuesta sin bloquear la pantalla.
        .task {
            await viewModel.loadMoviesIfNeeded()
        }
        // Búsqueda en TMDB: espera a que el usuario deje de escribir un momento antes de consultar.
        // Si escribe otra letra, SwiftUI cancela esta tarea y empieza otra con el texto nuevo.
        // Esta tarea también corre al regresar del detalle; search() reconoce que el texto no cambió
        // y conserva los resultados que ya estaban.
        .task(id: viewModel.searchText) {
            guard viewModel.isSearching else {
                await viewModel.search()
                return
            }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            await viewModel.search()
        }
        .navigationDestination(for: AppRoute.self) { route in
            switch route {
            case .favorites:
                FavoritesView(viewModel: viewModel.makeFavoritesViewModel())
            case .lists:
                ListsView(viewModel: viewModel.makeListsViewModel())
            }
        }
        .navigationDestination(for: Movie.self) { movie in
            MovieDetailView(viewModel: viewModel.makeMovieDetailViewModel(for: movie))
        }
        .alert("Cerrar sesión", isPresented: $viewModel.showLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar sesión", role: .destructive) {
                viewModel.logout()
            }
        } message: {
            Text("¿Estás seguro de que deseas salir de tu cuenta? Tus favoritos y listas se quedan guardados en este teléfono.")
        }
        .alert(
            "No se pudieron cargar más películas",
            isPresented: Binding(
                get: { viewModel.loadMoreErrorMessage != nil },
                set: { if !$0 { viewModel.loadMoreErrorMessage = nil } }
            )
        ) {
            Button("Aceptar", role: .cancel) { }
        } message: {
            Text(viewModel.loadMoreErrorMessage ?? "")
        }
    }

    // Header Bar con botones de listas, favoritos y cuenta
    private var headerBar: some View {
        AppHeaderBar {
            AppHeaderTitle(text: "TMDB MOVIES")

            Spacer()

            HStack(spacing: 16) {
                // Listas personalizadas
                NavigationLink(value: AppRoute.lists) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
                .accessibilityLabel("Mis listas")

                // Favoritos
                NavigationLink(value: AppRoute.favorites) {
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
                .accessibilityLabel(viewModel.hasFavorites ? "Favoritos, tienes películas guardadas" : "Favoritos")

                // Menú de Perfil / Cerrar Sesión
                Menu {
                    if !viewModel.currentUser.isEmpty {
                        Text(viewModel.isGuest ? "Sesión de invitado" : "Usuario: \(viewModel.currentUser)")
                    }

                    Button(role: .destructive) {
                        viewModel.requestLogout()
                    } label: {
                        Label("Cerrar sesión", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.black)
                }
                .accessibilityLabel("Mi cuenta")
            }
        }
    }

    // Buscador
    private var searchBar: some View {
        HStack(spacing: 14) {
            Text("Buscar")
                .font(.title3)
                .foregroundColor(.black)
                .accessibilityHidden(true)

            HStack {
                TextField("Título de la película", text: $viewModel.searchText)
                    .submitLabel(.search)
                    .autocorrectionDisabled()
                    .accessibilityLabel("Buscar película en TMDB")
                    .onSubmit {
                        Task {
                            await viewModel.search(force: true)
                        }
                    }

                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .accessibilityLabel("Borrar búsqueda")
                }
            }
            .borderedField(cornerRadius: 20, height: 44)
        }
    }

    // Resultados de la búsqueda en TMDB
    @ViewBuilder
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Resultados para \"\(viewModel.trimmedSearchText)\"")
                .font(.title3.weight(.bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .accessibilityAddTraits(.isHeader)

            switch viewModel.searchState {
            case .idle, .loading:
                loadingView("Buscando en TMDB…")

            case .results(let movies, let canLoadMore):
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(movies) { movie in
                        NavigationLink(value: movie) {
                            MovieCardView(movie: movie, style: .compact)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 20)

                if canLoadMore {
                    Button {
                        Task {
                            await viewModel.loadMoreSearchResults()
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if viewModel.isLoadingMoreResults {
                                ProgressView()
                            }
                            Text(viewModel.isLoadingMoreResults ? "Cargando…" : "Cargar más resultados")
                                .font(.headline)
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(Color.appCyan)
                        .cornerRadius(20)
                    }
                    .disabled(viewModel.isLoadingMoreResults)
                    .frame(maxWidth: .infinity)
                }

            case .empty:
                Text("No se encontraron películas con ese nombre.")
                    .font(.body)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)

            case .error(let message):
                messageView(
                    icon: "exclamationmark.triangle",
                    title: "No se pudo buscar",
                    message: message,
                    buttonTitle: "Reintentar"
                ) {
                    await viewModel.search(force: true)
                }
            }
        }
    }

    // MARK: - Estados de la consulta

    // Loading: mientras llega la respuesta de TMDB
    private func loadingView(_ text: String) -> some View {
        ProgressView(text)
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
    }

    // Empty y Error: ícono, mensaje y un botón para volver a consultar
    private func messageView(
        icon: String,
        title: String,
        message: String,
        buttonTitle: String,
        retry: @escaping () async -> Void
    ) -> some View {
        VStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 50))
                .foregroundColor(.gray)
                .accessibilityHidden(true)

            Text(title)
                .font(.title3.weight(.bold))
                .foregroundColor(.black)
                .multilineTextAlignment(.center)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)

            Button {
                Task {
                    await retry()
                }
            } label: {
                Text(buttonTitle)
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 10)
                    .background(Color.appCyan)
                    .cornerRadius(20)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 30)
        .padding(.top, 60)
    }
}

// Cada preview usa servicios de prueba configurados para ver un estado distinto, sin internet
#Preview("Content") {
    NavigationStack {
        HomeView(
            viewModel: HomeViewModel(
                authStore: AuthStore(isLoggedIn: true, currentUser: "Demo"),
                movieService: MockMovieService(totalPages: 3),
                favoritesService: MockFavoritesService(favorites: [Movie.sampleMovies[0]]),
                listsService: MockListsService.sample
            )
        )
    }
}

#Preview("Empty") {
    NavigationStack {
        HomeView(
            viewModel: HomeViewModel(
                authStore: AuthStore(isLoggedIn: true, currentUser: "Demo"),
                movieService: MockMovieService(moviesToReturn: []),
                favoritesService: MockFavoritesService(),
                listsService: MockListsService()
            )
        )
    }
}

#Preview("Error") {
    NavigationStack {
        HomeView(
            viewModel: HomeViewModel(
                authStore: AuthStore(isLoggedIn: true, currentUser: "Demo"),
                movieService: MockMovieService(errorToThrow: .noConnection),
                favoritesService: MockFavoritesService(),
                listsService: MockListsService()
            )
        )
    }
}
