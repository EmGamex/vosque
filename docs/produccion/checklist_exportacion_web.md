# Checklist y Especificaciones de Exportación Web (HTML5)

Este documento cubre los requisitos técnicos, configuraciones del motor Godot 4 y la lista de control de calidad para compilar y publicar *Vosque* de forma óptima en navegadores web de escritorio (Newgrounds e itch.io).

---

## 1. Configuración de Pantalla y Viewport

Para garantizar la estética claustrofóbica y una lectura espacial simétrica idéntica en cualquier pantalla:

* **Relación de Aspecto Cuadrada (1:1):**
  - **Resolución Base del Viewport:** $1080 \times 1080\text{ px}$ (`display/window/size/viewport_width` y `viewport_height`).
  - **Resolución de Ventana en Escritorio (Override):** $720 \times 720\text{ px}$ (`display/window/size/window_width_override` y `window_height_override`).
* **Parámetros de Estiramiento en Godot (`project.godot`):**
  - `window/stretch/mode = "canvas_items"` (o `"viewport"` según conveniencia para nitidez de sprites).
  - `window/stretch/aspect = "keep"`
* **Efecto Visual:** En monitores panorámicos (16:9 o 21:9), el motor introduce bandas negras laterales limpias (*pillarboxing*), manteniendo inalterada el área visible del bosque de $1080 \times 1080\text{ px}$.

---

## 2. Parámetros del Motor (Godot 4) y Presupuesto de Rendimiento

* **Renderizador Gráfico:** `gl_compatibility` (basado en WebGL 2.0). Ofrece la mayor tasa de cuadros y compatibilidad universal en navegadores de escritorio (Chrome, Firefox, Edge, Safari) sin requerir WebGPU.
* **Hilos de Ejecución (Threads Deshabilitados):**
  - **Parámetro del Preset:** `Export > Web > Thread Support = Disabled`.
  - **Justificación Crítica:** La activación de hilos múltiples en navegadores exige el aislamiento de origen cruzado mediante cabeceras HTTP `Cross-Origin-Opener-Policy (COOP)` y `Cross-Origin-Embedder-Policy (COEP)`. En plataformas como Newgrounds e itch.io, los juegos se ejecutan dentro de `<iframe>` con dominios de contenido segregados donde estas cabeceras causan bloqueos de carga. Deshabilitar hilos garantiza que el juego cargue instantáneamente y sin restricciones.
* **Exclusión de Herramientas de Desarrollo (`exclude_filter`):**
  - En `export_presets.cfg` dentro del preset `Web`, se debe definir:
    ```ini
    exclude_filter="addons/godot_ai/*, addons/personaje_tools/*, tests/*, docs/*"
    ```
  - **Efecto:** Mantiene el paquete `.pck` por debajo de ~15 MB, reduce la huella de memoria en el navegador y evita que clientes o servidores de integración MCP intenten ejecutarse en producción.
* **Desactivación de Módulos Innecesarios:**
  - En `project.godot`, evitar motores de física 3D adicionales como Jolt Physics (`3d/physics_engine`), ya que el proyecto es estrictamente 2D.
* **Control de Fill-Rate en Pantallas HiDPI (Retina / 4K):**
  - Mantener `window/stretch/aspect = "keep"` y verificar `display/window/dpi/allow_hidpi = false` (o controlado) para evitar que resoluciones 4K multipliquen por 4 el número de fragmentos procesados por los shaders y las luces 2D en GPUs integradas.
* **Pre-calentamiento (*Shader & Particle Warm-up*):**
  - Al compilar en WebGL 2.0, los shaders y partículas de `CPUParticles2D` (como las chispas de la nota o el shader de transición de iris) pueden provocar un micro-congelamiento (*stutter*) en su primer uso. Pre-calentar o pre-instanciar estos recursos en un frame oculto durante la pantalla de inicio asegura una experiencia fluida.
* **Exportación PWA:** Desactivada para Web estándar (a menos que se desee soporte offline explícito).

---

## 3. Manejo de Audio y Política de Reproducción del Navegador

Los navegadores modernos bloquean cualquier reproducción automática de audio hasta que el usuario interactúa activamente con el documento:

1. **Suspensión de `AudioContext`:** Al cargar la página web, el contexto de audio se encuentra en estado *suspended*.
2. **Desbloqueo en el Menú Principal:**
   - La arquitectura del juego sitúa al usuario en [`menu_inicio.tscn`](../../escenas/menu_inicio.tscn).
   - El primer clic sobre el botón "Jugar" (o la pulsación de `Espacio`/`Enter`) produce el evento de entrada necesario para que el navegador desbloquee el subsistema de audio sin arrojar advertencias ni cortar los sonidos del juego.
3. **Pausas y Cambio de Pestaña:** Al minimizar o cambiar de pestaña en el navegador, el motor pausa automáticamente el loop de audio principal evitando desincronizaciones sonoras.

---

## 4. Captura de Entrada y Focus en iframes

Al jugar en plataformas como itch.io o Newgrounds, presionar `Espacio` o las teclas de flecha puede provocar que la página externa haga scroll accidental:

1. **Captura Automática de Foco:**
   - En el `index.html` generado, el elemento `<canvas id="canvas">` debe recibir foco al hacer clic en cualquier parte de la ventana de juego:
     ```javascript
     canvas.addEventListener("click", () => {
         canvas.focus();
     });
     ```
2. **Anulación de Propagación de Scroll:**
   - La plantilla de exportación de Godot 4 ya captura la mayoría de eventos, pero si se detecta scroll de página en itch.io, se puede inyectar en la plantilla HTML:
     ```javascript
     window.addEventListener("keydown", function(e) {
         // Prevenir scroll en Espacio (32) y Flechas (37-40)
         if ([32, 37, 38, 39, 40].indexOf(e.keyCode) > -1) {
             e.preventDefault();
         }
     }, false);
     ```

---

## 5. Persistencia de Datos en Web (High Score)

Para conservar la puntuación máxima (*High Score*) entre partidas y recargas de página:

* **Mecanismo Primario (`user://` en Godot 4 Web):**
  - Godot 4 mapea de forma transparente la ruta `user://` hacia una base de datos local `IndexedDB` en el almacenamiento del navegador del usuario.
  - El uso de `ConfigFile` o `FileAccess` guardando en `user://savegame.cfg` persiste automáticamente.
* **Consideración en iframes:**
  - `IndexedDB` está aislada por el dominio del iframe de itch.io (`v6p9d9t4.ssl.hwcdn.net`) o Newgrounds (`uploads.ungrounded.net`). El guardado permanece intacto mientras el jugador no borre los datos de navegación de ese dominio específico.
* **Mecanismo Secundario (Fallback opcional vía `JavaScriptBridge`):**
  ```gdscript
  func guardar_record_web(puntuacion: int) -> void:
      if OS.has_feature("web"):
          JavaScriptBridge.eval("localStorage.setItem('vosque_high_score', '%d');" % puntuacion)

  func cargar_record_web() -> int:
      if OS.has_feature("web"):
          var val = JavaScriptBridge.eval("localStorage.getItem('vosque_high_score');")
          if val != null and str(val).is_valid_int():
              return int(str(val))
      return 0
  ```

---

## 6. Configuración en Plataformas de Publicación

### 6.1. itch.io
* **Kind of project:** `HTML` (You have a ZIP or HTML file that will be played in the browser).
* **Uploads:** Subir un único archivo `.zip` que contenga `index.html` y los archivos complementarios (`.js`, `.wasm`, `.pck`) en la **raíz del archivo comprimido** (sin carpetas intermedias).
* **Embed Options:**
  - Viewport dimensions: **$800 \times 800$ px** (o **$900 \times 900$ px** para monitores Full HD).
  - Checkbox: **"Enable fullscreen button"** (permite que el jugador expanda la experiencia con bordes negros limpios).
  - Checkbox: **"Automatically start on page load"**.

### 6.2. Newgrounds
* **Upload Type:** HTML5 / ZIP Game.
* **Archivos:** Mismo archivo `.zip` con `index.html` en la raíz.
* **Resolución Recomendada:** $800 \times 800$ px.

---

## 7. Checklist Pre-Vuelo para Publicación

Antes de subir cada nueva versión candidata:

- [ ] **Configuración del Motor:**
  - [ ] Renderer fijado en `gl_compatibility`.
  - [ ] Viewport configurado en $1080 \times 1080$ px con `canvas_items` / `keep`.
  - [ ] Hilos (`Threads`) deshabilitados en el preset Web.
- [ ] **Empaquetado:**
  - [ ] Compilación Web exportada con nombre de archivo base `index.html`.
  - [ ] Archivo `.zip` generado con todos los archivos exportados en la raíz.
- [ ] **Pruebas de Ejecución Local:**
  - [ ] Servir localmente mediante servidor HTTP (Godot 4 lo hace con el botón de reproducción Web del editor, o vía `python -m http.server`).
  - [ ] Comprobar ausencia de errores en la consola del navegador (`F12`).
  - [ ] Verificar que la barra espaciadora y las flechas no hagan scroll vertical en la página.
  - [ ] Comprobar que el sonido se active limpiamente al interactuar en el Menú de Inicio.
  - [ ] Forzar un Game Over, recargar la página web con `F5` y validar que el récord histórico se mantenga visible.
- [ ] **Validación en Navegadores:**
  - [ ] Google Chrome (Escritorio).
  - [ ] Mozilla Firefox (Escritorio).
  - [ ] Microsoft Edge (Escritorio).
