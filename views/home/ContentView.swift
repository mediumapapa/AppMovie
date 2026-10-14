//
//  ContentView.swift
//  movies_app
//
//  

import SwiftUI

struct ContentView: View {
    @Environment(AuthStore.self) private var authStore
    @Environment(FavoritesStore.self) private var favoritesStore
    
    // Guarda en tiempo real el texto que el usuario ingresa en el buscador
    @State private var searchText: String = ""
    
    // Alerta o confirmación para cerrar sesión
    @State private var showLogoutAlert: Bool = false
    
    // Filtro de resultados de búsqueda
    private var filteredMovies: [Movie] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return []
        }
        return Movie.sampleMovies.filter {
            $0.title.localizedCaseInsensitiveContains(query) ||
            $0.overview.localizedCaseInsensitiveContains(query)
        }
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
                    
                    if !searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        // MARK: - Resultados de Búsqueda
                        searchResultsSection
                    } else {
                        // MARK: - Secciones Normales del Home
                        // Sección 1: Popular this week
                        MovieSectionView(
                            title: "Popular this week",
                            movies: Movie.sampleMovies
                        )
                        
                        // Sección 2: Action
                        MovieSectionView(
                            title: "Action",
                            movies: Movie.sampleMovies
                        )
                        
                        // Sección 3: Drama
                        MovieSectionView(
                            title: "Drama",
                            movies: Movie.sampleMovies
                        )
                    }
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
        .navigationDestination(for: Movie.self) { movie in
            MovieDetail(movie: movie)
        }
        .alert("Cerrar Sesión", isPresented: $showLogoutAlert) {
            Button("Cancelar", role: .cancel) { }
            Button("Cerrar Sesión", role: .destructive) {
                authStore.logout()
            }
        } message: {
            Text("¿Estás seguro de que deseas salir de tu cuenta?")
        }
    }
    
    // Header Bar con botones funcionales
    private var headerBar: some View {
        HStack {
            Text("TMDB MOVIES")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
            
            Spacer()
            
            // Botones para Listas (+), Favoritos (corazón) y Perfil (cuenta)
            HStack(spacing: 16) {
                // Botón de listas (para futuras listas personalizadas)
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                }
                
                // Enlace directo a la pantalla de Favoritos
                NavigationLink(destination: FavoritesView()) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "heart")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.black)
                        
                        // Indicador si hay favoritos guardados
                        if !favoritesStore.favorites.isEmpty {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 9, height: 9)
                                .offset(x: 2, y: -2)
                        }
                    }
                }
                
                // Menú de Perfil / Cerrar Sesión
                Menu {
                    if !authStore.currentUser.isEmpty {
                        Text("Usuario: \(authStore.currentUser)")
                    }
                    Button(role: .destructive) {
                        showLogoutAlert = true
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
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 16)
        .background(Color.appCyan.ignoresSafeArea(edges: .top))
    }
    
    // Buscador 
    private var searchBar: some View {
        HStack(spacing: 14) {
            Text("Search")
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(.black)
            
            TextField("", text: $searchText)
                .padding(.horizontal, 14)
                .frame(height: 38)
                .background(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.black, lineWidth: 1.8)
                )
        }
    }
    
    // Resultados de búsqueda en vivo
    private var searchResultsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Resultados para \"\(searchText)\"")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)
                .padding(.horizontal, 20)
            
            if filteredMovies.isEmpty {
                Text("No se encontraron películas con ese nombre.")
                    .font(.system(size: 15))
                    .foregroundColor(.gray)
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)], spacing: 16) {
                    ForEach(filteredMovies) { movie in
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
        ContentView()
    }
    .environment(AuthStore(isLoggedIn: true, currentUser: "Demo"))
    .environment(FavoritesStore())
}
