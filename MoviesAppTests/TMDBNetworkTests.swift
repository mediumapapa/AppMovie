//
//  TMDBNetworkTests.swift
//  MoviesAppTests
//
//  Pruebas de MovieService y AuthService con respuestas HTTP simuladas.
//  StubURLProtocol intercepta cada solicitud de URLSession y regresa el JSON que la prueba indique,
//  así se revisa la URL, el encabezado con el token y el flujo de inicio de sesión sin salir a internet.
//

import XCTest
@testable import movies_app

// Responde las solicitudes de URLSession sin internet
final class StubURLProtocol: URLProtocol {
    // Recibe la solicitud y regresa (código HTTP, JSON)
    static var handler: ((URLRequest) throws -> (Int, String))?
    static var requests: [URLRequest] = []

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.append(request)
        do {
            guard let handler = Self.handler else { throw URLError(.notConnectedToInternet) }
            let (status, json) = try handler(request)
            let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(json.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    // URLSession convierte httpBody en un stream; aquí se lee de vuelta como JSON
    static func jsonBody(of request: URLRequest) -> [String: String] {
        guard let stream = request.httpBodyStream else { return [:] }
        stream.open()
        defer { stream.close() }
        var data = Data()
        var buffer = [UInt8](repeating: 0, count: 1024)
        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: buffer.count)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return (try? JSONDecoder().decode([String: String].self, from: data)) ?? [:]
    }
}

final class TMDBNetworkTests: XCTestCase {

    private func makeClient(token: String = "token-de-prueba") -> TMDBClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return TMDBClient(session: URLSession(configuration: configuration), token: token)
    }

    override func setUp() {
        super.setUp()
        StubURLProtocol.handler = nil
        StubURLProtocol.requests = []
    }

    private func queryItems(of request: URLRequest) -> [String: String] {
        let items = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
    }

    // MARK: - Películas

    // La búsqueda va a /search/movie con el texto, la página, el idioma y el token en el encabezado
    func testSearchSendsQueryPageAndToken() async throws {
        StubURLProtocol.handler = { _ in
            (200, #"{ "page": 2, "results": [ { "id": 438631, "title": "Dune", "overview": "Paul Atreides.", "poster_path": null } ], "total_pages": 3 }"#)
        }
        let service = MovieService(client: makeClient())

        let page = try await service.searchMovies(query: "dune parte", page: 2)

        let request = try XCTUnwrap(StubURLProtocol.requests.first)
        XCTAssertEqual(request.url?.path, "/3/search/movie")
        XCTAssertEqual(queryItems(of: request)["query"], "dune parte")
        XCTAssertEqual(queryItems(of: request)["page"], "2")
        XCTAssertEqual(queryItems(of: request)["language"], "es-MX")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer token-de-prueba")
        XCTAssertEqual(page, MoviePage(movies: [Movie(id: 438631, title: "Dune", overview: "Paul Atreides.", posterPath: "")], page: 2, totalPages: 3))
    }

    // Sin token no se sale a internet y el error dice qué hacer
    func testPlaceholderTokenFailsWithoutCallingTMDB() async {
        let service = MovieService(client: makeClient(token: TMDBClient.placeholderToken))

        do {
            _ = try await service.popularMovies(page: 1)
            XCTFail("Debería fallar sin token")
        } catch {
            XCTAssertEqual(error as? MovieServiceError, .missingToken)
        }
        XCTAssertTrue(StubURLProtocol.requests.isEmpty)
    }

    // Un 401 con status_code 7 es un token inválido, no una contraseña incorrecta
    func testInvalidTokenIsReportedAs401() async {
        StubURLProtocol.handler = { _ in
            (401, #"{ "status_code": 7, "status_message": "Invalid API key: You must be granted a valid key." }"#)
        }
        let service = MovieService(client: makeClient())

        do {
            _ = try await service.movies(forGenreID: 28, page: 1)
            XCTFail("Debería fallar con 401")
        } catch {
            XCTAssertEqual(error as? MovieServiceError, .badStatus(401))
        }
    }

    // MARK: - Inicio de sesión

    // Flujo oficial de TMDB: token nuevo → validar con usuario y contraseña → crear sesión
    func testLoginFollowsTMDBFlow() async throws {
        StubURLProtocol.handler = { request in
            switch request.url?.path {
            case "/3/authentication/token/new":
                return (200, #"{ "success": true, "expires_at": "2026-11-17 23:00:00 UTC", "request_token": "token-temporal" }"#)
            case "/3/authentication/token/validate_with_login":
                return (200, #"{ "success": true, "request_token": "token-temporal" }"#)
            case "/3/authentication/session/new":
                return (200, #"{ "success": true, "session_id": "sesion-123" }"#)
            default:
                return (404, #"{ "status_code": 34 }"#)
            }
        }
        let service = AuthService(client: makeClient())

        let session = try await service.login(username: "cinefilo", password: "secreta")

        XCTAssertEqual(session, UserSession(sessionID: "sesion-123", username: "cinefilo", isGuest: false))
        let requests = StubURLProtocol.requests
        XCTAssertEqual(requests.map { $0.httpMethod }, ["GET", "POST", "POST"])
        XCTAssertEqual(StubURLProtocol.jsonBody(of: requests[1]), [
            "username": "cinefilo",
            "password": "secreta",
            "request_token": "token-temporal"
        ])
        XCTAssertEqual(StubURLProtocol.jsonBody(of: requests[2]), ["request_token": "token-temporal"])
    }

    // TMDB responde 401 con status_code 30 cuando el usuario o la contraseña no coinciden
    func testWrongPasswordIsInvalidCredentials() async {
        StubURLProtocol.handler = { request in
            if request.url?.path == "/3/authentication/token/new" {
                return (200, #"{ "success": true, "request_token": "token-temporal" }"#)
            }
            return (401, #"{ "success": false, "status_code": 30, "status_message": "Invalid username and/or password: You did not provide a valid login." }"#)
        }
        let service = AuthService(client: makeClient())

        do {
            _ = try await service.login(username: "cinefilo", password: "otra")
            XCTFail("Debería rechazar la contraseña")
        } catch {
            XCTAssertEqual(error as? MovieServiceError, .invalidCredentials)
        }
        XCTAssertEqual(StubURLProtocol.requests.count, 2, "No se crea sesión si la contraseña es incorrecta")
    }

    func testGuestLoginUsesGuestSessionEndpoint() async throws {
        StubURLProtocol.handler = { _ in
            (200, #"{ "success": true, "guest_session_id": "invitado-456", "expires_at": "2026-11-18 23:00:00 UTC" }"#)
        }
        let service = AuthService(client: makeClient())

        let session = try await service.loginAsGuest()

        XCTAssertEqual(StubURLProtocol.requests.first?.url?.path, "/3/authentication/guest_session/new")
        XCTAssertEqual(session, UserSession(sessionID: "invitado-456", username: "Invitado", isGuest: true))
    }

    // Un token de solicitud vencido (status_code 33) es una falla del inicio de sesión,
    // no debe decir que el token de APIKeys.swift está mal
    func testExpiredRequestTokenIsLoginFailure() async {
        StubURLProtocol.handler = { request in
            if request.url?.path == "/3/authentication/token/new" {
                return (200, #"{ "success": true, "request_token": "token-temporal" }"#)
            }
            return (401, #"{ "success": false, "status_code": 33, "status_message": "Invalid request token: The request token is either expired or invalid." }"#)
        }
        let service = AuthService(client: makeClient())

        do {
            _ = try await service.login(username: "cinefilo", password: "secreta")
            XCTFail("Debería fallar")
        } catch {
            XCTAssertEqual(error as? MovieServiceError, .loginFailed)
        }
    }
}
