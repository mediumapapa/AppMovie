# TMDB Movies (`MoviesApp`)

Aplicación móvil nativa para iOS desarrollada en **SwiftUI** que permite explorar el catálogo de películas de **The Movie Database (TMDB)**, buscar títulos en tiempo real, consultar su sinopsis y administrar una colección personal de películas favoritas almacenada localmente en el dispositivo.

---

## Descripción

Las plataformas actuales suelen estar pensadas para usuarios que dependen de algoritmos de recomendación, notificaciones constantes y pantallas saturadas de menús, calificaciones y funciones sociales. Sin embargo, existe un público **"old school"** —veteranos del cine y personas generalmente mayores que ya tienen el hábito arraigado de ver películas— que sabe lo que busca, no necesita recomendaciones algorítmicas ni distracciones visuales y prefiere una herramienta directa, legible y sin complicaciones.

**Propósito de la aplicación:** ofrecer una experiencia **minimalista, clara y directa** pensada para este perfil de usuario. Permite consultar rápidamente el catálogo actualizado de TMDB (en español de México), buscar una película concreta, leer su sinopsis con tipografía clara y alto contraste, y llevar el registro de sus películas favoritas guardadas localmente en su teléfono, disponibles incluso sin conexión a internet.

---

## Integrantes

- **Santiago Guerrero Colín**
- **Alejandro Isaias Diaz Castellanos**
- **Alberto Vazquez Enriquez**

---

## Funcionalidades

Funcionalidades implementadas en la versión actual (MVP):

1. **Inicio y cierre de sesión (`LoginView` / `AuthStore`):**
   - Validación de campos de usuario/correo y contraseña con mensajes de error claros.
   - Botón para mostrar u ocultar la contraseña.
   - Enlaces directos al portal oficial de TMDB para **registro de cuenta nueva** y **recuperación de contraseña**.
   - Cierre de sesión con alerta de confirmación desde el menú de perfil en la pantalla principal.
2. **Exploración de películas en tiempo real (`HomeView` / `MovieService`):**
   - Consulta asíncrona a la API REST de TMDB para mostrar tres secciones en carruseles horizontales (`ScrollView`):
     - **Popular this week** (tendencias semanales).
     - **Action** (películas de acción).
     - **Drama** (películas de drama).
   - Descarga asíncrona de pósters oficiales (`AsyncImage`) con ícono de respaldo mientras cargan o cuando una película no tiene imagen.
   - Manejo explícito de los cuatro estados de red en pantalla: **Cargando (`Loading`)**, **Contenido (`Content`)**, **Sin resultados (`Empty`)** y **Error (`Error`)** con botón para **Reintentar**.
3. **Búsqueda local instantánea (`HomeViewModel`):**
   - Filtrado en vivo (insensible a mayúsculas, minúsculas y espacios extremos) tanto por **título** como por **sinopsis (`overview`)** sobre las películas cargadas en el Home, evitando resultados duplicados entre secciones.
4. **Detalle de película (`MovieDetailView`):**
   - Visualización de título, póster ampliado y sinopsis completa (`Overview`).
   - Botón interactivo para agregar o quitar la película de la colección de favoritos.
5. **Administración de favoritos con persistencia local (`FavoritesView` / `FavoritesService`):**
   - Almacenamiento persistente en el dispositivo mediante **SwiftData** (`@Model FavoriteMovie`), garantizando que no se guarden películas duplicadas gracias a su identificador único de TMDB.
   - Pantalla dedicada con cuadrícula a dos columnas, estado vacío informativo, eliminación rápida mediante el botón `"X"` e indicador visual (punto rojo) en el ícono de corazón de la barra superior del Home.

---

## Tecnologías

| Categoría | Tecnología / Herramienta | Uso en el proyecto |
|---|---|---|
| **Lenguaje** | Swift 5.9+ | Lógica de negocio, modelos, concurrencia (`async/await`, `@MainActor`) |
| **Interfaz de usuario** | SwiftUI | Vistas declarativas, `NavigationStack`, `ScrollView`, `LazyVGrid`, `AsyncImage` |
| **Arquitectura y estado** | Patrón MVVM + `Observation` (`@Observable`) | Separación de responsabilidades entre Modelos, Vistas, ViewModels y Servicios |
| **Red (Networking)** | `URLSession` + `Decodable` (`JSONDecoder`) | Consumo HTTP de la API REST v3 de TMDB y decodificación de respuestas JSON |
| **Servicio externo** | TMDB API v3 (`api.themoviedb.org/3`) | Catálogo de películas en tendencia, descubrimiento por género e imágenes (`image.tmdb.org`) |
| **Persistencia local** | SwiftData (`@Model`, `ModelContainer`, `ModelContext`) | Almacenamiento local en disco de las películas favoritas (`FavoriteMovie`) |
| **Pruebas unitarias** | XCTest | 25 pruebas unitarias automatizadas (favoritos, búsqueda, estados de carga y decodificación JSON) |
| **Entorno y control de versiones** | Xcode 15+ · Git y GitHub | Desarrollo, simulación en iOS, revisión por Pull Requests y control de código fuente |

---

## Requisitos

Para compilar y ejecutar el proyecto se requiere:

- **Sistema operativo:** macOS Sonoma (14.0) o superior.
- **IDE:** **Xcode 15.0** o superior (necesario por los frameworks `Observation` y `SwiftData`).
- **SDK / Destino:** Simulador de iOS o dispositivo físico con **iOS 17.0** o superior.
- **Red y cuenta externa:** Conexión a internet y una cuenta gratuita en [The Movie Database (TMDB)](https://www.themoviedb.org/) para obtener un **Token de acceso de lectura a la API** (*API Read Access Token*).

---

## Instalación y configuración

1. **Clonar el repositorio:**
   ```bash
   git clone https://github.com/mediumapapa/AppMovie.git
   cd AppMovie
   ```

2. **Preparar el proyecto en Xcode:**
   Como el archivo `.xcodeproj` no está versionado en el repositorio, si abres el proyecto por primera vez en una Mac nueva:
   - Crea un proyecto en Xcode de tipo **iOS → App** con nombre `movies_app` (Interface: **SwiftUI**, Storage: **SwiftData** o **None**, Testing System: **XCTest**).
   - Elimina los archivos de plantilla que genera Xcode y arrastra la carpeta `MoviesApp` al navegador del proyecto activando **Create groups** y marcando el target principal `movies_app` (excepto `APIKeys.swift.example`, que **no** debe agregarse a ningún target).
   - Arrastra la carpeta `MoviesAppTests` marcando únicamente el target de pruebas `MoviesAppTests`.

---

## Configuración de servicios externos (API de TMDB)

Por seguridad, el token de TMDB **no está incluido en el repositorio**. Cada integrante o evaluador debe configurar su propio archivo local antes de compilar:

1. En la carpeta `MoviesApp/Utils/`, haz una copia del archivo plantilla `APIKeys.swift.example` y nómbralo **`APIKeys.swift`**:
   ```bash
   cp MoviesApp/Utils/APIKeys.swift.example MoviesApp/Utils/APIKeys.swift
   ```
2. Inicia sesión en TMDB, entra a [https://www.themoviedb.org/settings/api](https://www.themoviedb.org/settings/api) y copia el **Token de acceso de lectura a la API** (*API Read Access Token*, la cadena larga en formato JWT que comienza con `eyJ...`).
3. Abre `MoviesApp/Utils/APIKeys.swift` y pega tu token reemplazando `"PEGA_AQUI_TU_TOKEN"`:
   ```swift
   enum APIKeys {
       static let tmdbReadAccessToken = "eyJhbGciOiJIUzI1NiJ9..."
   }
   ```
4. Verifica en Xcode que `APIKeys.swift` esté marcado dentro del **Target Membership** de la app (`movies_app`) y que `APIKeys.swift.example` **no** pertenezca a ningún target.

> `MoviesApp/Utils/APIKeys.swift` está registrado en `.gitignore`, por lo que Git nunca subirá tu credencial personal a GitHub. Si el token falta o es inválido, la pantalla principal mostrará el mensaje: *"TMDB rechazó el token (código 401). Revisa el archivo APIKeys.swift."*

---

## Ejecución

1. **Seleccionar simulador:** En la barra superior de Xcode, elige un simulador con iOS 17.0 o superior (por ejemplo, *iPhone 15* o *iPhone 16*).
2. **Compilar y ejecutar la aplicación:** Presiona **`⌘R`** (o `Product → Run`).
3. **Iniciar sesión en la app:** En la pantalla de Login, ingresa cualquier nombre de usuario/correo y contraseña no vacíos (por ejemplo, usuario `demo` y contraseña `1234`) y presiona **Ingresar**.
4. **Ejecutar las pruebas unitarias:** Presiona **`⌘U`** (o `Product → Test`) para correr las **25 pruebas unitarias** (`FavoritesTests`, `HomeSearchTests`, `HomeStateTests` y `TMDBDecodingTests`). Ninguna prueba requiere conexión a internet.

---

## Flujos

<img width="1920" height="1080" alt="flujo" src="https://github.com/user-attachments/assets/db712963-39be-4d88-b82b-d93a336aec27" />

1. Login → pantalla de inicio → lista de películas → detalle de la película
2. Login → pantalla de inicio → búsqueda → resultado → detalle de la película
3. Login → pantalla de inicio → favoritos → películas guardadas → detalle de la película
4. Login → pantalla de inicio → listas personalizadas *(pendiente)* → películas listadas → detalle de la película

---

## Especificación de pantallas

### **Login**

<img width="335" height="640" alt="image" src="https://github.com/user-attachments/assets/e5c9c35d-fd6f-4bab-95c4-9e5bac707c0e" />


Pantalla para iniciar sesión.

- En la parte superior estará la barra con el nombre de la aplicación, sin los botones de listas, favoritos ni cuenta, ya que el usuario aún no ha iniciado sesión.
- Se pedirá el correo electrónico y la contraseña; el campo de contraseña tendrá un ícono de ojo para mostrarla u ocultarla.
- Al presionar el botón "Ingresar" se validarán los datos. Si son correctos, nos llevará a la pantalla principal; si no, se mostrará un mensaje de error.
- Debajo del botón habrá un enlace "¿No tienes cuenta? Regístrate" para crear una cuenta nueva.
- Se dispondrá de la opción "¿Olvidaste tu contraseña?" para recuperar el acceso.

### **Home**<img width="1920" height="1080" alt="flujo" src="https://github.com/user-attachments/assets/846ef58c-be1a-4a68-90b2-ae1c19c40729" />


<img width="1080" height="1920" alt="Home" src="https://github.com/user-attachments/assets/63c5e557-2b4d-4fd7-abba-2154d2ea7ade" />

La pantalla principal de la aplicación.

- En la parte superior derecha estarán los botones para acceder a las listas personalizadas, favoritos y la cuenta del usuario.
- Se incorporará un buscador de películas; el resultado nos llevará a la pantalla de detalle de cada película.
- Se mostrará por secciones (popularidad y géneros) las películas disponibles mediante un `ScrollView` horizontal por sección (se eliminaron las flechas laterales del boceto original en `MovieSectionView` para mantener un diseño más limpio y minimalista basado únicamente en el desplazamiento táctil del `ScrollView`).
- Al presionar cualquier película, nos llevará a la pantalla de detalle.

### **Movie Detail**

<img width="1080" height="1920" alt="3" src="https://github.com/user-attachments/assets/e23e05a6-32fa-4f46-af7b-ee0ed5fc1b66" />

Pantalla de detalle de cada película.

- Nos mostrará información básica de cada película: título, portada de lanzamiento y una descripción general.
- En la parte inferior de la pantalla, se dispondrá de un botón para añadir a favoritos, y enseguida un botón para añadir a listas personalizadas.
- Al momento de presionar el botón de las listas personalizadas, nos mostrará una ventana para seleccionar a qué lista guardar la película o si se desea crear una nueva lista (pedirá el nombre).
- En la parte superior izquierda, se dispondrá de un botón de retroceso.

### **Favorites**

<img width="1080" height="1920" alt="2" src="https://github.com/user-attachments/assets/2ca49dae-680e-4589-b6d0-79296f233626" />

La pantalla de favoritos.

- Aquí se almacenarán las películas que deseemos añadir a favoritos.
- Al presionar cualquier película, nos llevará a la pantalla de detalle.
- Podremos eliminar películas de favoritos presionando la "X" ubicada en la esquina superior derecha de cada elemento.
- Del lado superior izquierdo de la pantalla, habrá una flecha de retroceso.

### **List** *(Funcionalidad pendiente)*

<img width="1080" height="1920" alt="4" src="https://github.com/user-attachments/assets/1156b120-4e81-4275-b541-60196193530c" />

Listas personalizadas.

- Aquí se mostrarán las listas personalizadas con las películas en cada una.
- Inmediatamente al costado derecho de la lista, habrá una flecha que nos permitirá seleccionar entre las listas que tengamos creadas.
- En la parte inferior de la pantalla, se dispondrá un botón (tres círculos) para cargar el resto de películas si es que es necesario.
- En la parte superior izquierda habrá un botón de retroceso.

---

## Arquitectura y organización del proyecto (MVVM)

El código sigue el patrón **Model - View - ViewModel (MVVM)**:

- **Model (`Models/`):** estructuras y modelos de datos (`Movie`, `MovieSection`, `FavoriteMovie` para SwiftData y `TMDBMovie` para decodificar el JSON de TMDB).
- **View (`Views/` y `Components/`):** vistas declarativas en SwiftUI que únicamente presentan el estado expuesto por su ViewModel y notifican interacciones del usuario.
- **ViewModel (`ViewModels/`):** clases `@Observable` que concentran la lógica de presentación, validación, filtrado y coordinación con los servicios (`HomeViewModel`, `LoginViewModel`, `MovieDetailViewModel`, `FavoritesViewModel`).
- **Services (`Services/`):** protocolos (`MovieServiceProtocol`, `FavoritesServiceProtocol`) con implementaciones reales en `Production/` (TMDB con `URLSession` y persistencia con `SwiftData`) y dobles de prueba en `Mock/` para `#Preview` y `XCTest`.

### Estructura de carpetas

```
MoviesApp/
├── Models/       → Movie, MovieSection, FavoriteMovie (@Model de SwiftData), TMDBMovie (JSON de TMDB)
├── State/        → AuthStore
├── Services/     → MovieServiceProtocol, MovieServiceError, FavoritesServiceProtocol
│   ├── Mock/       → MockMovieService, MockFavoritesService
│   └── Production/ → MovieService (TMDB), FavoritesService (SwiftData)
├── ViewModels/   → HomeViewModel + HomeState, LoginViewModel, MovieDetailViewModel, FavoritesViewModel
├── Views/        → Home, Login, MovieDetail, Favorites
├── Components/   → AppHeaderBar, BorderedFieldModifier, MovieCardView, MovieSectionView, MoviePosterView
├── Utils/        → AppColors, AppLinks, APIKeys (no se sube; ver configuración arriba)
└── Resources/    → Assets.xcassets
MoviesAppTests/   → FavoritesTests, HomeSearchTests, HomeStateTests, TMDBDecodingTests (XCTest)
Docs/             → Documentación técnica de cada práctica y diseño de navegación
```

### Documentación por práctica (`Docs/`)

- [Docs/navigation-and-state.md](Docs/navigation-and-state.md): Diseño inicial de navegación y estado (Práctica 3).
- [Docs/Practica-4.md](Docs/Practica-4.md): Flujo de navegación del MVP (Práctica 4).
- [Docs/Practica-5.md](Docs/Practica-5.md): Reorganización hacia MVVM (Práctica 5).
- [Docs/Practica-6.md](Docs/Practica-6.md): Persistencia con SwiftData y pruebas unitarias con XCTest (Práctica 6).
- [Docs/Practica-7.md](Docs/Practica-7.md): Integración con la API de TMDB, estados de carga y manejo de errores (Práctica 7).
- [Docs/Practica-8.md](Docs/Practica-8.md): Documentación técnica consolidada, decisiones de diseño y limitaciones conocidas (Práctica 8).
