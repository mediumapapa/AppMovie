import Foundation

// Películas de muestra para los #Preview y las pruebas.
// Los ids y los pósters son los reales de cada película en TMDB.
extension Movie {

    static let sampleMovies: [Movie] = [
        Movie(id: 693134, title: "Dune: Parte Dos", overview: "Paul Atreides se une a Chani y a los Fremen para buscar venganza.", posterPath: "/6o5cJjA4srfvU52UKWaqPUuPPgl.jpg"),
        Movie(id: 157336, title: "Interstellar", overview: "Un grupo de exploradores viaja a través de un agujero de gusano en el espacio.", posterPath: "/oBvINgU5r10WHvG6VSopCOlWtJP.jpg"),
        Movie(id: 329865, title: "Arrival", overview: "Una lingüista es reclutada para comunicarse con visitantes extraterrestres.", posterPath: "/dkYr7GA9F9Vps5QN74ycbbxMfiQ.jpg"),
        Movie(id: 27205, title: "Inception", overview: "Un ladrón que roba secretos a través de los sueños recibe la tarea de implantar una idea.", posterPath: "/xgPGDEKkBrXhPaNmwIlf8e2RCMk.jpg"),
        Movie(id: 872585, title: "Oppenheimer", overview: "La historia del científico estadounidense y su papel en el desarrollo de la bomba atómica.", posterPath: "/mJRUREPjTqqMEKwEiM2sdmIGngz.jpg"),
        Movie(id: 155, title: "The Dark Knight", overview: "Batman se enfrenta al Joker mientras este desata el caos sobre las calles de Gotham.", posterPath: "/vLFCrzI3V4kbze877tP1H7TqppL.jpg"),
        Movie(id: 299536, title: "Avengers: Infinity War", overview: "Los Vengadores se unen para evitar que Thanos reúna las seis gemas del infinito.", posterPath: "/G7GOAKUjxIjMUVKBhXOviohEB0.jpg"),
        Movie(id: 414906, title: "The Batman", overview: "En su segundo año de lucha contra el crimen, Batman investiga la corrupción en Gotham.", posterPath: "/kOD0qxiUmSg7M5LeHNWT6KffsNQ.jpg"),
        Movie(id: 335984, title: "Blade Runner 2049", overview: "Un nuevo Blade Runner descubre un secreto que lo lleva a buscar a Rick Deckard.", posterPath: "/cOt8SQwrxpoTv9Bc3kyce3etkZX.jpg"),
        Movie(id: 550, title: "Fight Club", overview: "Un empleado con insomnio y un vendedor de jabón forman un club de lucha clandestino.", posterPath: "/bI0BhpswEApC0B17RhLZtRVPZiQ.jpg")
    ]
}

// Servicio de prueba: no usa internet.
// Se puede configurar para ver cada estado del Home: con películas, sin resultados o con error.
final class MockMovieService: MovieServiceProtocol {

    // Lo que regresa cada consulta (en todas las páginas, salvo que pages diga otra cosa)
    var moviesToReturn: [Movie]
    // Películas de una página en particular, para probar "cargar más"
    var pages: [Int: [Movie]]
    // Cuántas páginas dice tener cada consulta
    var totalPages: Int
    // Si no es nil, cada consulta lanza este error en lugar de regresar películas
    var errorToThrow: MovieServiceError?

    // Registro de lo que se pidió, para revisarlo en las pruebas
    private(set) var searchedQueries: [String] = []
    private(set) var requestedPages: [Int] = []

    init(
        moviesToReturn: [Movie] = Movie.sampleMovies,
        pages: [Int: [Movie]] = [:],
        totalPages: Int = 1,
        errorToThrow: MovieServiceError? = nil
    ) {
        self.moviesToReturn = moviesToReturn
        self.pages = pages
        self.totalPages = totalPages
        self.errorToThrow = errorToThrow
    }

    func popularMovies(page: Int) async throws -> MoviePage {
        try result(page: page, movies: movies(forPage: page))
    }

    func movies(forGenreID genreID: Int, page: Int) async throws -> MoviePage {
        try result(page: page, movies: movies(forPage: page))
    }

    // Igual que TMDB, busca el texto en el título o en la sinopsis
    func searchMovies(query: String, page: Int) async throws -> MoviePage {
        searchedQueries.append(query)
        let matches = movies(forPage: page).filter {
            $0.title.localizedCaseInsensitiveContains(query) || $0.overview.localizedCaseInsensitiveContains(query)
        }
        return try result(page: page, movies: matches)
    }

    private func movies(forPage page: Int) -> [Movie] {
        pages[page] ?? moviesToReturn
    }

    private func result(page: Int, movies: [Movie]) throws -> MoviePage {
        requestedPages.append(page)
        if let error = errorToThrow {
            throw error
        }
        return MoviePage(movies: movies, page: page, totalPages: totalPages)
    }
}
