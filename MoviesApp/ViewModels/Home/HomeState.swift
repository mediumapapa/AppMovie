import Foundation

// Estados de la consulta del Home a TMDB.
// Es la única fuente de verdad: las secciones solo existen dentro de .content,
// así la pantalla nunca puede mostrar películas y un error al mismo tiempo.
enum HomeState: Equatable {
    case loading                   // Esperando la respuesta de TMDB
    case content([MovieSection])   // Llegaron películas para mostrar
    case empty                     // La consulta salió bien, pero no hay películas
    case error(String)             // La consulta falló; trae el mensaje para el usuario
}

// Estados del buscador. Funciona igual que HomeState, pero para /search/movie.
enum SearchState: Equatable {
    case idle                                   // No hay texto que buscar
    case loading                                // Esperando la respuesta de TMDB
    case results([Movie], canLoadMore: Bool)    // Películas encontradas y si hay otra página
    case empty                                  // TMDB no encontró nada con ese texto
    case error(String)                          // La búsqueda falló; trae el mensaje para el usuario
}
