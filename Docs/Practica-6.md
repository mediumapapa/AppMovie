# Práctica 6: Pruebas unitarias y persistencia con SwiftData

En esta práctica los favoritos dejaron de vivir solo en memoria. Ahora se guardan en el teléfono con SwiftData y siguen ahí después de cerrar la app. También agregamos pruebas con XCTest para la regla de favoritos y para el buscador del Home.

## Qué encontramos antes de empezar

- `Movie` tenía `var id = UUID()`. Ese id se generaba de nuevo cada vez que se abría la app, así que una película guardada nunca iba a coincidir con la misma película al volver a abrirla.
- `FavoritesStore` empezaba con una película de muestra (`Movie.sampleMovies[0]`). Con persistencia eso ya no tiene sentido, porque la volvería a agregar en cada arranque aunque el usuario la hubiera quitado.
- Los favoritos eran un arreglo en memoria. Al cerrar la app se perdían.

## Persistencia local

### Qué se guarda

Solo los favoritos. Es la colección personal del MVP y es lo único que el usuario espera encontrar igual al volver a abrir la app. El login sigue simulado y las películas del Home vienen del servicio, así que no se guardan.

Por cada favorito se guarda un `FavoriteMovie` (`Models/FavoriteMovie.swift`):

| Campo | Para qué |
|---|---|
| `movieID` | El id de la película en TMDB. Con él se reconoce la película. Tiene `@Attribute(.unique)`. |
| `title`, `overview`, `posterPath` | Lo que necesita la tarjeta de Favoritos para mostrarse sin pedir nada a la API. |
| `addedAt` | Fecha en que se agregó, para mostrar los favoritos en ese orden. |

Cuando se conecte TMDB, la API va a seguir siendo la fuente de las películas. Lo guardado solo dice cuáles eligió el usuario y lo mínimo para dibujarlas.

### Id estable

`Movie` ahora tiene `let id: Int` y las películas de prueba usan su id real de TMDB (por ejemplo, Interstellar es 157336 y Fight Club es 550). Así el id es el mismo en cada arranque y va a ser el mismo cuando los datos lleguen de la API.

### Cómo se configuró SwiftData

1. `movies_appApp` crea un `ModelContainer(for: FavoriteMovie.self)` en su `init`. Ese contenedor guarda en disco.
2. Con el contenedor se crea `FavoritesService` y con el servicio se crea `FavoritesStore`, que se pasa a los ViewModels igual que antes.
3. El contenedor también se pone en la escena con `.modelContainer(...)`, por si después alguna vista necesita `@Query`.

### Capas

```
FavoritesView / MovieDetailView / HomeView
        ↓ (por su ViewModel)
FavoritesStore          (State)     estado que leen las vistas
        ↓
FavoritesServiceProtocol (Services) contrato: leer, agregar, quitar
        ↓
FavoritesService        (Services) implementación con ModelContext
        ↓
FavoriteMovie           (Models)    modelo @Model guardado en disco
```

- `FavoritesService` hace el trabajo con SwiftData: `FetchDescriptor` para leer ordenado por `addedAt`, `#Predicate` para buscar por `movieID`, `insert`, `delete` y `save()`.
- `FavoritesStore` ya no edita el arreglo a mano. Después de agregar o quitar, vuelve a leer lo guardado. Así hay una sola fuente de verdad (la base de SwiftData) y el arreglo `favorites` que leen las vistas siempre coincide con ella.
- Los ViewModels (`FavoritesViewModel`, `MovieDetailViewModel`, `HomeViewModel`) y las vistas no cambiaron. Siguen llamando a `add`, `remove`, `toggle` e `isFavorite`.

### Duplicados

Se controlan en dos lugares:

- `FavoritesService.add` busca primero si ya existe un registro con ese `movieID`. Si existe, no inserta nada.
- `@Attribute(.unique)` en `movieID` hace que la base tampoco acepte dos registros con el mismo id, por si en el futuro otra parte del código inserta directo.

La comparación es por id y no por título. Si la misma película llega después con otro título o con el póster de la API, se reconoce como la misma.

### Previews

Los `#Preview` ya no pueden usar `FavoritesStore()`. Ahora usan `FavoritesStore.inMemory(with:)`, que arma SwiftData solo en memoria. Así los previews no tocan los favoritos reales del simulador.

## Pruebas unitarias

Las pruebas están en la carpeta `MoviesAppTests/` y usan XCTest. Ninguna depende de internet ni de la API. Cada prueba de favoritos crea su propio contenedor de SwiftData en memoria, así no comparten datos entre ellas y se pueden correr las veces que sea.

### `FavoritesStoreTests`: regla de favoritos

| Prueba | Tipo | Qué comprueba |
|---|---|---|
| `testAddSavesMovieInFavorites` | Normal | Al agregar Dune queda en la lista, `isFavorite` es verdadero y hay 1 registro en SwiftData. |
| `testRemoveDeletesOnlyThatMovie` | Normal | Con Dune e Interstellar guardadas, al quitar Dune solo queda Interstellar. |
| `testAddingSameMovieTwiceKeepsOneRecord` | Límite | Agregar la misma película dos veces deja 1 registro. |
| `testMovieIsRecognizedByIdEvenIfTitleChanges` | Límite | La misma película con otro título (como si viniera de la API) no se guarda otra vez y se conserva la original. |
| `testToggleTwiceLeavesMovieOutOfFavorites` | Límite | Tocar el corazón dos veces la agrega y la quita; no queda nada guardado. |
| `testNewStoreStartsWithoutFavorites` | Sin resultados | Un store nuevo empieza vacío (ya no trae la película de muestra). |
| `testRemovingMovieThatIsNotSavedChangesNothing` | Entrada inválida | Quitar una película que no está guardada no borra nada ni truena. |
| `testFavoritesRemainAfterReopeningTheStore` | Persistencia | Guarda en un archivo temporal, suelta ese contenedor y abre uno nuevo sobre el mismo archivo. Los favoritos siguen ahí. Al final borra el archivo. |

Además de revisar el arreglo del store, varias pruebas cuentan los registros directo en SwiftData con `fetchCount`, para comprobar que no se guardaron duplicados en la base.

### `HomeSearchTests`: buscador del Home

Usan `HomeViewModel` con `MockMovieService`, que tiene siempre las mismas 10 películas.

| Prueba | Tipo | Qué comprueba |
|---|---|---|
| `testSearchFindsMovieIgnoringUppercase` | Normal | "INTERSTELLAR" encuentra Interstellar. |
| `testSearchAlsoLooksInOverview` | Normal | "gotham" encuentra The Dark Knight y The Batman por su sinopsis. |
| `testSearchIgnoresSpacesAroundText` | Límite | "   arrival  " encuentra Arrival. |
| `testOnlySpacesIsNotASearch` | Límite | Solo espacios no cuenta como búsqueda y no regresa resultados. |
| `testSearchWithoutMatchesReturnsEmptyList` | Sin resultados | "Titanic" no está en los datos y regresa una lista vacía. |

## Cómo correr las pruebas en Xcode

El repositorio no trae el `.xcodeproj`, así que el target de pruebas se agrega en el proyecto de cada quien:

1. En Xcode: File > New > Target… > iOS > Unit Testing Bundle.
2. Nombre: `MoviesAppTests`. Testing System: XCTest. Target to be tested: el target de la app.
3. Borrar el archivo de ejemplo que crea Xcode y arrastrar la carpeta `MoviesAppTests` del repositorio al proyecto, marcando solo el target `MoviesAppTests`.
4. Si el target de la app no se llama `movies_app`, cambiar la línea `@testable import movies_app` en los dos archivos.
5. Correr con ⌘U.

## Verificación manual

1. Abrir la app, iniciar sesión y entrar al detalle de una película.
2. Tocar "Add Favorite" y revisar que aparezca en Favoritos y que salga el punto rojo en el corazón del Home.
3. Detener la app desde Xcode, volver a abrirla e iniciar sesión. La película debe seguir en Favoritos.
4. Quitarla con la "X", cerrar y volver a abrir. Ya no debe aparecer.
5. Revisar que el login, el buscador, el detalle y cerrar sesión funcionen igual que antes.

## Pendientes

- Cuando se conecte TMDB, el `posterPath` guardado va a ser la ruta del póster de la API y no el nombre de un ícono de SF Symbols. La tarjeta tendrá que cargar la imagen con esa ruta.
- Los favoritos no están separados por usuario. Si en el futuro se usa la sesión real de TMDB, habría que decidir si se guardan por cuenta o se sincronizan con los favoritos de TMDB.
- Si se cambia `FavoriteMovie` más adelante (agregar o quitar campos), hay que revisar la migración de SwiftData para no perder lo guardado.
- Las listas personalizadas siguen sin implementarse.
