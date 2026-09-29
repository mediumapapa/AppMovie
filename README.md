## Proyecto Integrador

Elección de proyecto:

**Opción A** · Aplicación de películas con TMDB 

**Objetivo**: Permitir explorar películas, buscar una película, consultar su información y administrar favoritas.

Equipo:

- Guerrero Colín Santiago
- Diaz Castellanos Alejandro Isaias
- Vazquez Enriquez Alberto

## Flujos 

<img width="1526" height="1381" alt="image" src="https://github.com/user-attachments/assets/34e957b1-a63a-4bb1-a08b-f67b5c9ad7af" />


1) Login → pantalla de inicio → lista de películas → detalle de la película
2) Login → pantalla de inicio → búsqueda → resultado → detalle de la película
3) Login → pantalla de inicio → favoritos → películas guardadas → detalle de la película
4) Login → pantalla de inicio → listas personalizadas → películas listadas → detalle de la película


## Especificación de pantallas

### **Login**

<img width="335" height="640" alt="image" src="https://github.com/user-attachments/assets/e5c9c35d-fd6f-4bab-95c4-9e5bac707c0e" />

Pantalla para iniciar sesión.

- En la parte superior estará la barra con el nombre de la aplicación, sin los botones de listas, favoritos ni cuenta, ya que el usuario aún no ha iniciado sesión
- Se pedirá el correo electrónico y la contraseña; el campo de contraseña tendrá un ícono de ojo para mostrarla u ocultarla
- Al presionar el botón "Ingresar" se validarán los datos. Si son correctos, nos llevará a la pantalla principal; si no, se mostrará un mensaje de error
- Debajo del botón habrá un enlace "¿No tienes cuenta? Regístrate" para crear una cuenta nueva
- Se dispondrá de la opción "¿Olvidaste tu contraseña?" para recuperar el acceso


#### **Home**

<img width="1080" height="1920" alt="1" src="https://github.com/user-attachments/assets/f943af33-af07-4580-9b54-4cb9f9933d61" />

La pantalla principal de la aplicación. 
- En la parte superior derecha estarán los botones para acceder a las listas personalizadas, favoritos y la cuenta del usuario
- Se incorporará un buscador de películas, el resultado nos llevará a la pantalla de detalle de cada película
- Se mostrará por secciones (popularidad y géneros) las películas disponibles. En cada sección habrá flechas de navegación para recorrer toda la lista
- Al presionar cualquier película, nos llevará a la pantalla de detalle


### Movie Detail

<img width="1080" height="1920" alt="3" src="https://github.com/user-attachments/assets/e23e05a6-32fa-4f46-af7b-ee0ed5fc1b66" />

Pantalla de detalle de cada película
- Nos mostrará información básica de cada película: Titulo, portada de lanzamiento y una descripción general
- En la parte inferior de la pantalla, se dispondrá de un botón para añadir a favoritos, y enseguida un botón para añadir a listas personalizadas
- Al momento de presionar el botón de las listas personalizadas, nos mostrará una ventana para seleccionar a qué lista guardar la película o si se desea crear una nueva lista (pedirá el nombre).
- En la parte superior izquierda, se dispondrá de un botón de retroceso

### Favorites

<img width="1080" height="1920" alt="2" src="https://github.com/user-attachments/assets/2ca49dae-680e-45b9-b6d0-79296f233626" />

La pantalla de favoritos.
- Aquí se almacenarán las películas que deseemos añadir a favoritos
- Al presionar cualquier película, nos llevará a la pantalla de detalle
- Podremos eliminar películas de favoritos, presionando la "X" ubicada en la esquina superior derecha de cada elemento
- Del lado superior izquierdo de la pantalla, habrá una flecha de retroceso 

### List

<img width="1080" height="1920" alt="4" src="https://github.com/user-attachments/assets/1156b120-4e81-4275-b541-60196193530c" />

Listas personalizadas-
- Aquí se mostrará las listas personalizadas con las películas en cada una
- Inmediatamente al costado derecho de la lista, habrá una flecha que nos permitirá seleccionar entre las listas que tengamos creadas
- En la parte inferior de la pantalla, se dispondrá un botón (tres círculos) para cargar el resto de películas si es que es necesario
- En la parte superior izquierda habrá un botón de retroceso
