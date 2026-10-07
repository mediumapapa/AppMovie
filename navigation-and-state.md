
1.- Mapa de navegación de las pantallas del MVP.

<img width="1920" height="1080" alt="Historia de Instagram Pantalla Teléfono Celular Fin de Semana Llamando Foto Relax Minimalista Negro" src="https://github.com/user-attachments/assets/b2afce0f-c187-4c70-9c4a-44e98975bff0" />

- Al abrir la app: si no hay sesión guardada se muestra Login; si ya hay sesión, se abre directo Home.
- Login → Home: al presionar "Ingresar" con datos correctos.
- Home → Movie Detail: al tocar una película de cualquier sección o un resultado de la búsqueda.
- Home → Favorites: con el botón de corazón.
- Home → List: con el botón "+".
- Favorites → Movie Detail: al tocar una película guardada.
- List → Movie Detail: al tocar una película de la lista.
- Movie Detail → ventana de "Add List": al tocar "Add List" se abre una ventana para elegir la lista o crear una nueva. Al terminar se regresa al detalle.
- Favorites, List y Movie Detail regresan a la pantalla anterior con el botón de retroceso.
- Home → Login: al cerrar sesión desde el botón de cuenta.

2.- Información por pantalla, indicando qué muestra, recibe, modifica y necesita conservar.

A) Pantalla de login:

- Muestra: la barra con el nombre de la app, los campos de usuario y contraseña (con el ícono de ojo), el botón "Ingresar", los enlaces "¿Olvidaste tu contraseña?" y "Regístrate", y un mensaje de error si los datos son incorrectos.
- Recibe: nada de otra pantalla, porque es la primera.
- Modifica: la sesión. Manda el usuario y la contraseña a la API de TMDB y, si son correctos, TMDB responde con un session_id.
- Necesita conservar: solo el session_id, para no pedir el login cada vez que se abre la app. La contraseña no se guarda.
- Nota: la API de TMDB pide nombre de usuario y no correo, por eso el campo de correo cambia a "Usuario".

B) Pantalla de Home:

- Muestra: la barra con los botones de listas, favoritos y cuenta; el buscador; y las películas por secciones (populares de la semana y por género), con flechas para recorrer cada sección.
- Recibe: las películas que devuelve la API de TMDB.
- Modifica: el texto del buscador. Cuando hay texto, en lugar de las secciones se muestran los resultados de la búsqueda.
- Necesita conservar: el texto de búsqueda y las películas descargadas mientras la app está abierta. No guarda nada permanente.

C) Pantalla de Movie Detail:

- Muestra: el título, la portada y la descripción de la película; los botones "Add Favorite" y "Add List"; y el botón de retroceso.
- Recibe: la película que el usuario tocó en Home, Favorites o List.
- Modifica: los favoritos (agrega la película) y las listas (agrega la película a una lista existente o a una nueva).
- Necesita conservar: nada propio. Los favoritos y las listas se guardan en la cuenta de TMDB del usuario.

D) Pantalla de Favorites:

- Muestra: las películas favoritas del usuario, cada una con una "X" para quitarla, y la flecha de retroceso.
- Recibe: los favoritos del usuario, que se piden a TMDB usando la sesión.
- Modifica: los favoritos, cuando se quita una película con la "X".
- Necesita conservar: nada propio. Los favoritos viven en la cuenta de TMDB, por eso siguen ahí aunque se cierre la app.

E) Pantalla de List:

- Muestra: el nombre de la lista seleccionada con la flecha para cambiar de lista, las películas de esa lista, el botón de tres círculos para cargar más y el botón de retroceso.
- Recibe: las listas del usuario y sus películas, que se piden a TMDB usando la sesión.
- Modifica: solo cuál lista está seleccionada.
- Necesita conservar: la lista seleccionada mientras la pantalla está abierta. Las listas viven en la cuenta de TMDB.

3.- Organización del estado, indicando dónde debería vivir cada dato y justificando la decisión.

Seguimos tres reglas:

- Si un dato lo usa una sola pantalla, vive en esa pantalla con @State.
- Si lo usan varias pantallas, vive en un objeto compartido para toda la app (una clase @Observable que las pantallas leen con @Environment), así todas ven el mismo dato.
- Los favoritos y las listas deben seguir existiendo al cerrar la app, así que se guardan en la cuenta de TMDB, porque no tenemos una base de datos propia como Firebase. Lo único que se guarda en el dispositivo es el session_id.

Dónde vive cada dato:

- Usuario, contraseña, mostrar u ocultar contraseña y mensaje de error: viven en Login con @State. Solo los usa esa pantalla y no deben guardarse.
- Sesión (session_id): vive en un objeto compartido, porque toda la app necesita saber si hay un usuario dentro. Con ella se decide si se muestra Login o Home, y se piden a TMDB los favoritos y las listas del usuario. También se guarda en el dispositivo para que siga ahí al cerrar la app. Proponemos guardarla en Keychain, que es donde iOS guarda datos secretos, porque TMDB pide cuidar el session_id como una contraseña.
- Texto de búsqueda: vive en Home con @State (ya existe en nuestro código como searchText). Solo lo usa Home.
- Películas de las secciones y resultados de búsqueda: viven en Home con @State, porque solo Home los muestra. Vienen de TMDB y no se guardan; se vuelven a pedir al abrir la app.
- Película seleccionada: hoy vive en Home con @State (selectedMovie) para abrir el detalle. Con NavigationLink ya no hace falta guardarla: se pasa como parámetro a Movie Detail, porque el detalle solo la lee.
- Favoritos: se guardan en la cuenta de TMDB. Dentro de la app viven en un objeto compartido, porque los usan dos pantallas (Movie Detail agrega y Favorites muestra y quita) y las dos deben ver lo mismo.
- Listas personalizadas: igual que los favoritos. Se guardan en la cuenta de TMDB y viven en un objeto compartido, porque Movie Detail agrega películas y List las muestra.
- Lista seleccionada: vive en List con @State. Solo la usa esa pantalla.
- Nombre de una lista nueva: vive en la ventana de "Add List" con @State. Es un dato temporal mientras el usuario escribe.

4.- Estrategia de navegación, explicando cómo se moverá el usuario entre las pantallas y qué mecanismos de SwiftUI podrían utilizarse.

- Login o Home al abrir la app: la vista principal revisa con un if si hay sesión. Si no hay, muestra Login; si hay, muestra Home. Así el usuario no puede regresar a Login con el botón de retroceso.
- Home, Favorites, List y Movie Detail: usamos NavigationStack con NavigationLink. Cada pantalla se abre encima de la anterior y el botón de retroceso regresa a la pantalla de donde se vino.
- Movie Detail: hoy se abre con fullScreenCover desde Home. Proponemos abrirla con NavigationLink, porque se llega a ella desde tres pantallas (Home, Favorites y List). Así las tres la abren de la misma forma y el botón de retroceso aparece solo, sin repetir en cada pantalla el código para abrirla y cerrarla.
- Ventana de "Add List": se abre con .sheet, porque es una acción corta y al cerrarla el usuario sigue en la misma película.
- Búsqueda: se queda en Home. Los resultados se muestran ahí mismo y al tocar uno se abre Movie Detail.
- "Regístrate" y "¿Olvidaste tu contraseña?": son enlaces (Link) que abren la página de TMDB en el navegador, porque el registro y la recuperación de contraseña se hacen en su sitio web.
- Cerrar sesión: proponemos hacerlo desde el botón de cuenta. Se borra el session_id y, como la vista principal depende de la sesión, la app vuelve a mostrar Login.
