//
//  TMDBDecodingTests.swift
//  MoviesAppTests
//
//  Pruebas de la decodificación del JSON de TMDB con JSONDecoder.
//  El JSON de ejemplo tiene la misma forma que regresa /trending/movie/week.
//

import XCTest
@testable import movies_app

@MainActor
final class TMDBDecodingTests: XCTestCase {

    // Incluye campos que la app no usa (vote_average, page...) y una película sin póster
    private let sampleJSON = """
    {
      "page": 1,
      "results": [
        {
          "id": 157336,
          "title": "Interestelar",
          "overview": "Un grupo de exploradores viaja a través de un agujero de gusano.",
          "poster_path": "/oBvINgU5r10WHvG6VSopCOlWtJP.jpg",
          "vote_average": 8.4
        },
        {
          "id": 1,
          "title": "Película sin póster",
          "overview": "",
          "poster_path": null
        }
      ],
      "total_pages": 1,
      "total_results": 2
    }
    """

    func testDecodesMoviesFromTMDBResponse() throws {
        let movieList = try JSONDecoder().decode(TMDBMovieList.self, from: Data(sampleJSON.utf8))
        let movies = movieList.results.map { $0.movie }

        XCTAssertEqual(movies.map { $0.id }, [157336, 1])
        XCTAssertEqual(movies[0].title, "Interestelar")
        XCTAssertEqual(movies[0].posterURL?.absoluteString, "https://image.tmdb.org/t/p/w500/oBvINgU5r10WHvG6VSopCOlWtJP.jpg")
    }

    // poster_path en null no rompe la decodificación; la tarjeta muestra el ícono
    func testMovieWithoutPosterHasNoPosterURL() throws {
        let movieList = try JSONDecoder().decode(TMDBMovieList.self, from: Data(sampleJSON.utf8))

        XCTAssertNil(movieList.results[1].movie.posterURL)
    }

    // Respuesta sin películas (como /discover cuando no hay resultados)
    func testDecodesEmptyResults() throws {
        let json = #"{ "page": 1, "results": [], "total_pages": 1, "total_results": 0 }"#

        let movieList = try JSONDecoder().decode(TMDBMovieList.self, from: Data(json.utf8))

        XCTAssertTrue(movieList.results.isEmpty)
    }

    // Si el JSON no trae "results" (por ejemplo, el error de TMDB), decodificar falla
    func testDecodingFailsWithUnexpectedJSON() {
        let json = #"{ "status_code": 7, "status_message": "Invalid API key" }"#

        XCTAssertThrowsError(try JSONDecoder().decode(TMDBMovieList.self, from: Data(json.utf8)))
    }
}
