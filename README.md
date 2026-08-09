# TravelApp - Ecosistema Kiosco Inteligente de Abordaje

* **Autor:** Mauricio Gabriel Vazquez
* **Institución:** Universidad Tecnológica de Querétaro (UTEQ)
* **Carrera:** Ingeniería en Desarrollo y Gestión de Software
* **Materia:** Desarrollo para Dispositivos Inteligentes (Mayo-Agosto 2026)
* **Evaluación:** Evaluación 2

## Descripción del Proyecto
* Ecosistema de software diseñado para simular el proceso de abordaje y monitoreo de pasajeros.
* Integración en tiempo real de tres dispositivos físicos/emulados funcionando simultáneamente.
* Uso de WebSockets para telemetría bidireccional y alertas instantáneas.
* Simulación de conexión Bluetooth Low Energy (BLE) para la transmisión de signos vitales.
* Implementación de una Progressive Web App (PWA) optimizada para pantallas 10-foot.

## Arquitectura y Tecnologías
* **Backend:** Node.js, Express, Socket.io, Prisma (Base de datos).
* **Smart TV (PWA):** Vanilla JavaScript, HTML5, CSS3, Service Workers.
* **Aplicación Móvil:** Flutter (Dart), Provider, HTTP, Socket.io-client.
* **Wearable (Wear OS):** Flutter (Dart).

---

## Instrucciones de Ejecución

Para replicar este entorno de pruebas y evaluar el funcionamiento simultáneo de los dispositivos, sigue los pasos a continuación en el orden establecido:

### 1. Inicializar el Servidor (Backend)
* Abre una terminal y navega hasta la carpeta del servidor Node.js.
* Instala las dependencias necesarias ejecutando el comando: `npm install`
* Crea un archivo `.env` en la raíz de esta carpeta con las credenciales de tu base de datos y tu `JWT_SECRET`.
* Inicia el servidor ejecutando: `node server.js`
* Verifica en la consola que el servidor esté corriendo en el puerto 3000 (o el puerto configurado).
* **Nota importante:** Identifica la dirección IPv4 local de la máquina que aloja el servidor (ej. `192.168.100.x`), ya que los clientes móviles la necesitarán.

### 2. Desplegar la Smart TV (PWA)
* Navega a la carpeta `pwa_smart_tv`.
* Asegúrate de que las variables `API_URL`, `TV_API_URL` y las conexiones del Socket en `app.js` apunten a la IP del servidor.
* Despliega la aplicación utilizando un servidor de desarrollo local (como la extensión Live Server en VS Code).
* Abre Chrome, accede a la URL local (ej. `http://127.0.0.1:5500`) y presiona `F12` para abrir las DevTools.
* Configura la vista de dispositivos para simular una pantalla con resolución de `1920x1080` píxeles.

### 3. Ejecutar el Emulador Wear OS (Reloj)
* Abre una nueva terminal y navega a la carpeta `wearable_app`.
* Asegúrate de que la variable `baseUrl` en el archivo `main.dart` apunte a la IP de tu servidor Node.js.
* Descarga las dependencias ejecutando: `flutter pub get`
* Inicia un emulador de Wear OS (API level correspondiente).
* Compila y ejecuta la aplicación con el comando: `flutter run`
* Una vez abierta, presiona "Vincular Teléfono" para poner el dispositivo en modo emparejamiento (Advertising).

### 4. Ejecutar la Aplicación Móvil (Teléfono)
* Abre una nueva terminal y navega a la carpeta `app_telefono`.
* Verifica nuevamente que `apiUrl` y `socketUrl` en `main.dart` coincidan con la IP de tu servidor.
* Descarga las dependencias con: `flutter pub get`
* Inicia un emulador de teléfono Android o conecta un dispositivo físico.
* Compila y ejecuta la aplicación usando: `flutter run`
* Inicia sesión con las credenciales de prueba.
* Navega a la pestaña "Mis Viajes" y presiona "Vincular Wearable Independiente" para completar la sincronización BLE.

