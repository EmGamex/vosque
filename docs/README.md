# Vosque - Game Design Document (GDD)

Bienvenido a la documentación oficial y modular de diseño de **Vosque**.

---

## Ficha Técnica

| Parámetro | Detalle |
| :--- | :--- |
| **Proyecto** | Vosque |
| **Género** | Arcade 2D / Top-Down Survival Horror |
| **Plataformas** | Web (HTML5) para Newgrounds e itch.io (PC / Navegadores de escritorio) |
| **Relación de Aspecto** | 1:1 (Viewport cuadrado, ej. 720x720 px / 1080x1080 px) |
| **Motor** | Godot Engine 4 (Compatibility Renderer) |
| **Pipeline Gráfico** | 3D Mockup (Blender) ➔ Vector Inking & Color (Inkscape) ➔ Motor 2D (Godot 4) |
| **Ventana de Producción** | 4 semanas (Lanzamiento para Halloween) |

---

## 1. Visión General

### 1.1. Elevator Pitch
Un juego arcade de supervivencia y terror de vista cenital inspirado en la atmósfera y tensión de obras como *Slender*: controlas a un protagonista desorientado en un bosque oscuro armado únicamente con una linterna deficiente. El objetivo es recoger tantas notas como sea posible mientras evitas a una criatura hostil que se vuelve progresivamente más rápida, agresiva e insistente con cada página recogida.

### 1.2. Pilares de Diseño
1. **Inmediatez Arcade:** Sesiones de 60 a 120 segundos; controles instantáneos, reintentos rápidos y enfoque en superar la puntuación máxima (*High Score*).
2. **Tensión y Atmósfera de Terror:** Sensación constante de vulnerabilidad, oscuridad opresiva, pasos inquietantes en el bosque y una amenaza implacable que acecha al jugador.
3. **Producción Eficiente Asistida:** Alcance acotado a un solo mapa cerrado, pipeline híbrido 3D-Vectorial (Blender + Inkscape) para gráficos rápidos y consistentes, y lógica directa asistida por IA/MCP en Godot.

---

## Índice de Documentación Modular

Para facilitar la lectura y desarrollo, la documentación está dividida en las siguientes áreas técnicas:

### [Gameplay y Mecánicas](gameplay/mecanicas_y_entidades.md)
- [Mecánicas y Entidades](gameplay/mecanicas_y_entidades.md): Core loop, jugador, IA del monstruo, notas y diseño del bosque.
- [Dificultad y Balance](gameplay/dificultad_y_balance.md): Progresión por notas, fórmulas de velocidad y escalado.

### [Arte y Pipeline Visual](arte/pipeline_hibrido.md)
- [Pipeline Híbrido](arte/pipeline_hibrido.md): Flujo paso a paso (Blender ➔ Inkscape ➔ Godot).
- [Guía de Estilo y Assets](arte/guia_estilo_y_assets.md): Estética visual y checklist de sprites necesarios.

### [Interfaz y Audio](interfaz_y_audio/controles_y_hud.md)
- [Controles y HUD](interfaz_y_audio/controles_y_hud.md): Entradas de teclado, HUD in-game, flash de nota y pantalla de Game Over.
- [Audio y Feedback](interfaz_y_audio/audio_y_feedback.md): Efectos de sonido, detección de proximidad y tensión auditiva.

### [Producción](produccion/roadmap_y_hitos.md)
- [Roadmap e Hitos](produccion/roadmap_y_hitos.md): Calendario de 4 semanas hacia Halloween (Gantt y entregables semanales).
- [Checklist de Exportación Web](produccion/checklist_exportacion_web.md): Parámetros para HTML5, itch.io y Newgrounds en Godot 4.
