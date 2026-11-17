//
//  movies_appApp.swift
//  movies_app
//
//  Created by Alberto Ávila Aguilar on 18/09/26.
//

import SwiftUI
import SwiftData

@main
struct movies_appApp: App {
    // Contenedor de SwiftData. Guarda favoritos y listas en el teléfono para que sigan ahí al volver a abrir la app.
    // Se conserva aquí mientras la app está abierta; a los servicios solo se les pasa su contexto.
    private let modelContainer: ModelContainer

    // Sesión de TMDB. Se recupera del Llavero al abrir la app, así no hay que iniciar sesión cada vez.
    @State private var authStore = AuthStore(authService: AuthService(), storage: KeychainSessionStorage())

    // Servicios reales. Los previews y las pruebas usan los de Mock/.
    private let movieService: MovieServiceProtocol = MovieService()
    private let favoritesService: FavoritesServiceProtocol
    private let listsService: ListsServiceProtocol

    init() {
        let container: ModelContainer
        do {
            container = try ModelContainer(for: FavoriteMovie.self, MovieList.self, MovieListEntry.self)
        } catch {
            fatalError("No se pudo crear el contenedor de SwiftData: \(error)")
        }

        modelContainer = container
        favoritesService = FavoritesService(context: container.mainContext)
        listsService = ListsService(context: container.mainContext)
    }

    var body: some Scene {
        WindowGroup {
            if authStore.isLoggedIn {
                NavigationStack {
                    HomeView(
                        viewModel: HomeViewModel(
                            authStore: authStore,
                            movieService: movieService,
                            favoritesService: favoritesService,
                            listsService: listsService
                        )
                    )
                }
            } else {
                LoginView(viewModel: LoginViewModel(authStore: authStore))
            }
        }
    }
}
