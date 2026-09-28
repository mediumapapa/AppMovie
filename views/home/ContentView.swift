//
//  ContentView.swift
//  movies_app
//
//  
//

import SwiftUI

struct ContentView: View {
    //guarda en tiempo real el texto que el usuario ingresa en el buscador
    @State private var searchText: String = ""

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

                    MovieSectionView(
                        title: "Drama",
                        movies: Movie.sampleMovies
                    )
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .background(Color.white.ignoresSafeArea())
    }
    
    // Header Bar
    private var headerBar: some View {
        HStack {
            Text("TMDB MOVIES")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.black)
            
            Spacer()
            
            // Botones para Agregar, Favoritos y Perfil
            HStack(spacing: 16) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Image(systemName: "heart")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.black)
                
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.black)
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
            Text("Serch")
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
}

#Preview {
    ContentView()
}

