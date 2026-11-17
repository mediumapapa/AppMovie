# TMDB Movies (`MoviesApp`)

Aplicación móvil nativa para iOS desarrollada en **SwiftUI** que permite explorar el catálogo de películas de **The Movie Database (TMDB)**, buscar cualquier título del catálogo, consultar su sinopsis, administrar una colección de películas favoritas y organizar **listas personalizadas con notas propias**, todo almacenado localmente en el dispositivo.

---

## Descripción

Las plataformas actuales suelen estar pensadas para usuarios que dependen de algoritmos de recomendación, notificaciones constantes y pantallas saturadas de menús, calificaciones y funciones sociales. Sin embargo, existe un público **"old school"** —veteranos del cine y personas generalmente mayores que ya tienen el hábito arraigado de ver películas— que sabe lo que busca, no necesita recomendaciones algorítmicas ni distracciones visuales y prefiere una herramienta directa, legible y sin complicaciones.

**Propósito de la aplicación:** ofrecer una experiencia **minimalista, clara y directa** pensada para este perfil de usuario. Permite consultar rápidamente el catálogo actualizado de TMDB (en español de México), buscar una película concreta, leer su sinopsis con tipografía clara y alto contraste, llevar el registro de sus películas favoritas y armar sus propias listas con una pequeña nota sobre cada película, guardadas en su teléfono y disponibles incluso sin conexión a internet.

---

## Integrantes

- **Santiago Guerrero Colín**
- **Alejandro Isaias Diaz Castellanos**
- **Alberto Vazquez Enriquez**

---

## Funcionalidades

1. **Inicio de sesión con TMDB (`LoginView` / `AuthStore` / `AuthService`):**
   - Inicio de sesión real con el **usuario y la contraseña de una cuenta de TMDB**, siguiendo el flujo oficial de la API v3 (token de solicitud → validación con usuario y contraseña → `session_id`).
   - Botón **"Entrar como invitado"** que abre una sesión de invitado de TMDB, para usar la app sin cuenta.
   - La sesión se guarda en el **Llavero (Keychain)** del teléfono: al volver a abrir la app se entra directo al Home. La contraseña nunca se guarda.
   - Mensajes de error claros (campos vacíos, usuario o contraseña incorrectos, correo sin confirmar, sin internet, token faltante), botón para mostrar u ocultar la contraseña y enlaces al portal de TMDB para **registrarse** y **recuperar la contraseña**.
   - Cierre de sesión con alerta de confirmación desde el menú de perfil; la sesión también se cierra en TMDB.
2. **Exploración de películas (`HomeView` / `MovieService`):**
   - Tres secciones en carruseles horizontales que se piden a TMDB **al mismo tiempo** (`async let`): **Populares de la semana**, **Acción** y **Drama**.
   - Tarjeta **"Ver más"** al final de cada carrusel para cargar la siguiente página de TMDB sin repetir películas.
   - Pósters descargados con `AsyncImage` y un ícono de respaldo mientras cargan o cuando la película no tiene imagen.
   - Estados en pantalla: **Cargando**, **Contenido**, **Sin resultados** y **Error** con botón **Reintentar**.
3. **Búsqueda global (`HomeViewModel` / `GET /search/movie`):**
   - Busca en **todo el catálogo de TMDB**, no solo en las películas del Home. Consulta un momento después de que el usuario deja de escribir y cancela la búsqueda anterior si sigue escribiendo.
   - Botón **"Cargar más resultados"** para las siguientes páginas, botón para borrar la búsqueda y mensajes de "sin resultados" o error con **Reintentar**.
4. **Detalle de película (`MovieDetailView`):**
   - Título, póster ampliado, sinopsis de TMDB y la **nota personal** del usuario, en una pantalla con desplazamiento para que nada se corte.
   - Botones fijos abajo para **agregar o quitar de favoritos** y **agregar a lista** (indica en cuántas listas está la película).
5. **Listas personalizadas (`ListsView` / `AddToListSheet` / `ListsService`):**
   - Desde el detalle, **"Agregar a lista"** abre una ventana para marcar en qué listas guardar la película, **crear una lista nueva** escribiendo su nombre y escribir una **pequeña sinopsis o nota personal** (hasta 300 caracteres). Los cambios se guardan al momento, sin botón "Guardar".
   - Pantalla **Mis listas** (botón de lista en la barra superior del Home): muestra la lista seleccionada con la nota de cada película; la **flecha a la derecha del nombre** permite elegir entre las listas creadas, crear otra o eliminarla.
   - Las películas se muestran de cinco en cinco; el **botón de tres puntos** de abajo carga el resto.
   - Se quita una película de una lista con la **"X"**; tocarla abre su detalle.
   - Se guardan con **SwiftData** (`MovieList` y `MovieListEntry`); al borrar una lista se borran sus películas y notas.
6. **Favoritos con persistencia local (`FavoritesView` / `FavoritesService`):**
   - Guardados en el teléfono con **SwiftData** (`@Model FavoriteMovie`), sin duplicados gracias al identificador único de TMDB.
   - Cuadrícula a dos columnas, estado vacío informativo, eliminación con la **"X"** e indicador (punto rojo) en el corazón de la barra superior del Home.
7. **Accesibilidad:**
   - Textos con estilos del sistema que crecen con el **tamaño de letra** elegido en el iPhone.
   - Etiquetas de **VoiceOver** en todos los botones que solo tienen ícono (listas, favoritos, cuenta, "X", regresar, mostrar contraseña).
   - Gesto de **deslizar desde el borde izquierdo** para regresar, además de los botones de regreso.
   - Interfaz completa en **español**, con un diseño claro de alto contraste que se mantiene aunque el iPhone esté en modo oscuro.

---

## Tecnologías

| Categoría | Tecnología / Herramienta | Uso en el proyecto |
|---|---|---|
| **Lenguaje** | Swift 5.9+ | Lógica de negocio, modelos, concurrencia (`async/await`, `async let`, `@MainActor`) |
| **Interfaz de usuario** | SwiftUI | Vistas declarativas, `NavigationStack`, `ScrollView`, `LazyVGrid`, `AsyncImage`, `Form`, `sheet` |
| **Arquitectura y estado** | Patrón MVVM + `Observation` (`@Observable`) | Separación de responsabilidades entre Modelos, Vistas, ViewModels y Servicios |
| **Red (Networking)** | `URLSession` + `Decodable` (`JSONDecoder`) | Cliente compartido `TMDBClient` para películas, búsqueda e inicio de sesión |
| **Servicio externo** | TMDB API v3 (`api.themoviedb.org/3`) | Tendencias, descubrimiento por género, búsqueda, autenticación e imágenes (`image.tmdb.org`) |
| **Persistencia local** | SwiftData (`@Model`, `ModelContainer`, `ModelContext`) | Favoritos (`FavoriteMovie`) y listas personalizadas (`MovieList`, `MovieListEntry`) |
| **Seguridad** | Keychain (`Security`) | Guardar la sesión de TMDB cifrada en el teléfono |
| **Pruebas unitarias** | XCTest + `URLProtocol` simulado | 62 pruebas automatizadas (favoritos, listas, login, búsqueda, paginación, estados del Home, red y JSON) |
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

2. **Abrir el proyecto en Xcode:**
   ```bash
   open movies_app.xcodeproj
   ```
   El proyecto ya incluye el target de la app (`movies_app`), el target de pruebas (`MoviesAppTests`) y un esquema compartido `movies_app` con el que funcionan `⌘R` y `⌘U`. No hace falta crear nada a mano.
   - Si al compilar desde la terminal aparece *"xcodebuild requires Xcode"*, apunta las herramientas a Xcode con `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`.

3. **Configurar tu token de TMDB** (siguiente sección).

---

## Configuración del token de TMDB (en cualquier equipo)

La app necesita un **Token de acceso de lectura** de TMDB para pedir películas e iniciar sesión. Ese token es una credencial personal, así que **no está en el repositorio**: cada computadora donde se compile la app necesita su propio archivo `MoviesApp/Utils/APIKeys.swift`, que Git ignora (está en `.gitignore`).

### 1. Obtener un token (una sola vez por persona)

1. Crea una cuenta gratuita en [themoviedb.org/signup](https://www.themoviedb.org/signup) y confirma tu correo.
2. Entra a [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api) y solicita una clave de API (tipo *Developer*, uso personal/educativo).
3. Copia el **Token de acceso de lectura a la API** (*API Read Access Token*): la cadena larga que empieza con `eyJ...`. No es la "Clave de la API" corta de 32 caracteres.

### 2. Ponerlo en la computadora donde vas a compilar

1. Clona el repositorio y abre `movies_app.xcodeproj`.
2. Compila una vez (`⌘B`). La fase **"Crear APIKeys.swift si falta"** copia la plantilla `APIKeys.swift.example` como `MoviesApp/Utils/APIKeys.swift` y Xcode muestra un aviso. También puedes crearlo tú:
   ```bash
   cp MoviesApp/Utils/APIKeys.swift.example MoviesApp/Utils/APIKeys.swift
   ```
3. Abre `MoviesApp/Utils/APIKeys.swift` y reemplaza `"PEGA_AQUI_TU_TOKEN"` por tu token:
   ```swift
   enum APIKeys {
       static let tmdbReadAccessToken = "eyJhbGciOiJIUzI1NiJ9..."
   }
   ```
4. Ejecuta la app (`⌘R`). No hay que mover archivos ni tocar *Target Membership*: el proyecto ya incluye `APIKeys.swift` en el target `movies_app`.
5. Comprueba que tu token no se va a subir: `git status` **no** debe mostrar `APIKeys.swift`.

### 3. Instalarla en un iPhone físico

El token queda dentro de la app compilada, así que el iPhone no necesita configurar nada; solo hay que instalarle la app desde una Mac que ya tenga su `APIKeys.swift`:

1. Conecta el iPhone por cable (o en la misma red Wi-Fi después de emparejarlo) y elígelo como destino en la barra superior de Xcode.
2. En el target `movies_app` → **Signing & Capabilities**, marca *Automatically manage signing* y elige tu **Team** (sirve un Apple ID gratuito: *Xcode → Settings → Accounts → +*). Si Xcode dice que el *Bundle Identifier* ya está en uso, cámbialo por uno tuyo, por ejemplo `com.tunombre.movies-app`.
3. En el iPhone activa **Configuración → Privacidad y seguridad → Modo de desarrollador** y reinícialo.
4. Presiona `⌘R`. La primera vez, en el iPhone ve a **Configuración → General → VPN y gestión de dispositivos** y confía en tu perfil de desarrollador.
5. Con un Apple ID gratuito la app deja de abrir después de 7 días; vuelve a ejecutarla desde Xcode para renovarla.

### 4. Equipos de trabajo y evaluadores

- **Cada integrante o evaluador usa su propio token** en su computadora. Así nadie depende de la cuenta de otra persona y, si un token se filtra, solo hay que cambiar ese.
- **Nunca subas `APIKeys.swift`**, ni pegues el token en issues, Pull Requests, capturas de pantalla o chats grupales.
- Si un token se llegó a publicar, regenéralo en [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api); el anterior deja de funcionar.
- Para iniciar sesión dentro de la app se puede usar una cuenta de TMDB o el botón **"Entrar como invitado"**; las dos opciones necesitan el token configurado.

### Mensajes que indican un problema con el token

| Mensaje en la app | Qué significa | Qué hacer |
|---|---|---|
| *"Falta configurar el token de TMDB…"* | `APIKeys.swift` todavía tiene el texto de la plantilla | Pega tu token en `APIKeys.swift` y vuelve a ejecutar |
| *"TMDB rechazó el token (código 401)…"* | El token está mal copiado, incompleto o fue regenerado | Copia otra vez el *Token de acceso de lectura* completo |
| *"Usuario o contraseña de TMDB incorrectos."* | El token funciona, pero las credenciales de la cuenta no | Revisa el usuario (no el correo) y la contraseña de TMDB, o entra como invitado |

---

## Ejecución

1. **Seleccionar simulador:** En la barra superior de Xcode, elige un simulador con iOS 17.0 o superior (por ejemplo, *iPhone 15* o *iPhone 16*).
2. **Compilar y ejecutar la aplicación:** Presiona **`⌘R`** (o `Product → Run`).
3. **Iniciar sesión en la app:** escribe el **usuario y la contraseña de tu cuenta de TMDB** y presiona **Ingresar**, o toca **Entrar como invitado**. La próxima vez que abras la app entrarás directo al Home.
4. **Ejecutar las pruebas unitarias:** Presiona **`⌘U`** (o `Product → Test`) para correr las **62 pruebas unitarias**. Ninguna prueba requiere conexión a internet ni token.

---

## Flujos

<img width="1920" height="1080" alt="flujo" src="https://github.com/user-attachments/assets/db712963-39be-4d88-b82b-d93a336aec27" />

1. Login → pantalla de inicio → lista de películas → detalle de la película
2. Login → pantalla de inicio → búsqueda → resultado → detalle de la película
3. Login → pantalla de inicio → favoritos → películas guardadas → detalle de la película
4. Login → pantalla de inicio → listas personalizadas → películas listadas → detalle de la película

---

## Especificación de pantallas

### **Login**

<img width="335" height="640" alt="image" src="https://github.com/user-attachments/assets/e5c9c35d-fd6f-4bab-95c4-9e5bac707c0e" />


Pantalla para iniciar sesión.

- En la parte superior está la barra con el nombre de la aplicación, sin los botones de listas, favoritos ni cuenta, ya que el usuario aún no ha iniciado sesión.
- Se pide el **usuario de TMDB** y la contraseña; el campo de contraseña tiene un ícono de ojo para mostrarla u ocultarla.
- Al presionar el botón "Ingresar" TMDB valida los datos. Si son correctos, nos lleva a la pantalla principal; si no, se muestra un mensaje de error.
- El botón "Entrar como invitado" permite usar la app sin cuenta de TMDB.
- Debajo hay un enlace "¿No tienes cuenta? Regístrate" para crear una cuenta nueva y la opción "¿Olvidaste tu contraseña?" para recuperar el acceso.

### **Home**

<img width="1080" height="1920" alt="Home" src="https://github.com/user-attachments/assets/63c5e557-2b4d-4fd7-abba-2154d2ea7ade" />

La pantalla principal de la aplicación.

- En la parte superior derecha están los botones para acceder a las listas personalizadas, favoritos y la cuenta del usuario.
- El buscador consulta todo el catálogo de TMDB; cada resultado nos lleva a la pantalla de detalle de la película.
- Se muestran por secciones (popularidad y géneros) las películas disponibles mediante un `ScrollView` horizontal por sección. Al final de cada carrusel, la tarjeta "Ver más" carga más películas (se eliminaron las flechas laterales del boceto original en `MovieSectionView` para mantener un diseño más limpio y minimalista).
- Al presionar cualquier película, nos lleva a la pantalla de detalle.

### **Movie Detail**

<img width="1080" height="1920" alt="3" src="https://github.com/user-attachments/assets/e23e05a6-32fa-4f46-af7b-ee0ed5fc1b66" />

Pantalla de detalle de cada película.

- Muestra información básica de cada película: título, portada, sinopsis y, si existe, la nota personal del usuario.
- En la parte inferior de la pantalla está el botón para añadir a favoritos y enseguida el botón para añadir a listas personalizadas.
- Al presionar el botón de listas personalizadas se abre una ventana para seleccionar en qué listas guardar la película, crear una nueva lista (pide el nombre) y escribir una nota personal.
- En la parte superior izquierda está el botón de retroceso.

### **Favorites**

<img width="1080" height="1920" alt="2" src="https://github.com/user-attachments/assets/2ca49dae-680e-4589-b6d0-79296f233626" />

La pantalla de favoritos.

- Aquí se almacenan las películas que deseemos añadir a favoritos.
- Al presionar cualquier película, nos lleva a la pantalla de detalle.
- Podemos eliminar películas de favoritos presionando la "X" ubicada en la esquina superior derecha de cada elemento.
- Del lado superior izquierdo de la pantalla hay una flecha de retroceso.

### **List**

<img width="1080" height="1920" alt="4" src="https://github.com/user-attachments/assets/1156b120-4e81-4275-b541-60196193530c" />

Listas personalizadas.

- Muestra la lista seleccionada con sus películas y la nota personal de cada una.
- Inmediatamente al costado derecho del nombre de la lista hay una flecha que permite seleccionar entre las listas creadas, crear una nueva o eliminar la actual.
- En la parte inferior de la pantalla hay un botón (tres círculos) para cargar el resto de películas cuando la lista tiene más de cinco.
- En la parte superior izquierda hay un botón de retroceso.

---

## Arquitectura y organización del proyecto (MVVM)

El código sigue el patrón **Model - View - ViewModel (MVVM)**:

- **Model (`Models/`):** estructuras y modelos de datos (`Movie`, `MovieSection`, `MoviePage`, `UserSession`, `FavoriteMovie` y `MovieList`/`MovieListEntry` para SwiftData, y los modelos `Decodable` de TMDB).
- **View (`Views/` y `Components/`):** vistas declarativas en SwiftUI que únicamente presentan el estado expuesto por su ViewModel y notifican interacciones del usuario.
- **ViewModel (`ViewModels/`):** clases `@Observable` que concentran la lógica de presentación, validación, búsqueda, paginación y coordinación con los servicios.
- **Services (`Services/`):** protocolos (`MovieServiceProtocol`, `AuthServiceProtocol`, `FavoritesServiceProtocol`, `ListsServiceProtocol`) con implementaciones reales en `Production/` (TMDB con `URLSession`, SwiftData y Keychain) y dobles de prueba en `Mock/` para `#Preview` y `XCTest`.

### Estructura de carpetas

```
movies_app.xcodeproj → Proyecto de Xcode (targets movies_app y MoviesAppTests, esquema compartido)
MoviesApp/
├── Models/       → Movie, MovieSection, MoviePage, UserSession, FavoriteMovie, MovieList (+ MovieListEntry),
│                   TMDBMovie y TMDBAuth (JSON de TMDB)
├── State/        → AuthStore (sesión)
├── Services/     → Protocolos de películas, sesión, favoritos y listas + MovieServiceError
│   ├── Mock/       → MockMovieService, MockAuthService, MockFavoritesService, MockListsService
│   └── Production/ → TMDBClient, MovieService, AuthService, KeychainSessionStorage, FavoritesService, ListsService
├── ViewModels/   → Home (+ HomeState), Login, MovieDetail, Favorites, Lists (ListsViewModel, AddToListViewModel)
├── Views/        → Home, Login, MovieDetail, Favorites, Lists (ListsView, AddToListSheet)
├── Components/   → AppHeaderBar, BorderedFieldModifier, MovieCardView, MovieSectionView, MoviePosterView
├── Utils/        → AppColors, AppLinks, APIKeys (no se sube; ver configuración del token)
└── Resources/    → Assets.xcassets (ícono de la app y colores)
MoviesAppTests/   → FavoritesTests, ListsTests, AuthTests, HomeSearchTests, HomeStateTests,
                    TMDBDecodingTests, TMDBNetworkTests (XCTest)
Docs/             → Documentación técnica de cada práctica y diseño de navegación
```

### Documentación por práctica (`Docs/`)

- [Docs/navigation-and-state.md](Docs/navigation-and-state.md): Diseño inicial de navegación y estado (Práctica 3).
- [Docs/Practica-4.md](Docs/Practica-4.md): Flujo de navegación del MVP (Práctica 4).
- [Docs/Practica-5.md](Docs/Practica-5.md): Reorganización hacia MVVM (Práctica 5).
- [Docs/Practica-6.md](Docs/Practica-6.md): Persistencia con SwiftData y pruebas unitarias con XCTest (Práctica 6).
- [Docs/Practica-7.md](Docs/Practica-7.md): Integración con la API de TMDB, estados de carga y manejo de errores (Práctica 7).
- [Docs/Practica-8.md](Docs/Practica-8.md): Documentación técnica consolidada, decisiones de diseño y limitaciones conocidas (Práctica 8).
- [Docs/funcionalidades-finales.md](Docs/funcionalidades-finales.md): Listas personalizadas, búsqueda global, paginación, inicio de sesión con TMDB, proyecto de Xcode y pruebas nuevas (versión final).
