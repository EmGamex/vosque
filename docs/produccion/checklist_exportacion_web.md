# Checklist y Especificaciones de Exportación Web

Este documento cubre los requisitos técnicos y la configuración recomendada para compilar y publicar *Vosque* en navegadores web (Newgrounds e itch.io) con Godot 4.

---

## 1. Configuración de Pantalla y Viewport

* **Relación de Aspecto:** Cuadrada **1:1** (resolución base $720 \times 720$ px o $800 \times 800$ px).
* **Modo de Estiramiento en Godot:**
  - Stretch Mode: `viewport`
  - Stretch Aspect: `keep`
* **Propósito:** Centrar el área cuadrada de juego con barras laterales limpias, garantizando un campo de visión idéntico en cualquier monitor sin deformaciones y generando un efecto visual claustrofóbico.

---

## 2. Parámetros del Motor (Godot 4)

* **Renderizador:** `Compatibility` (basado en WebGL 1/2) para máxima compatibilidad con navegadores de escritorio sin requerir soporte de WebGPU.
* **Hilos de Ejecución (Threads):**
  - **Deshabilitar hilos avanzados** en el preset de exportación Web si no son indispensables.
  - *Motivo:* Evita la necesidad obligatoria de cabeceras HTTP `Cross-Origin-Opener-Policy (COOP)` y `Cross-Origin-Embedder-Policy (COEP)` en Newgrounds e itch.io, garantizando que el juego cargue al instante sin restricciones de iframe.

---

## 3. Checklist de Publicación

- [ ] Preset Web creado en Godot con renderer `Compatibility`.
- [ ] Exportación empaquetada como archivo `.zip` con el `index.html` en la raíz.
- [ ] Pruebas en navegadores principales (Chrome, Firefox, Edge).
- [ ] Verificación de captura de teclado (para evitar que la barra espaciadora o flechas hagan scroll en la página de itch.io/Newgrounds).
- [ ] Comprobación del guardado de puntuación máxima (*High Score*).
