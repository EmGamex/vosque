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
3. **Producción Eficiente Asistida:** Alcance acotado a un mapa de 4 sectores mutables (cuadrícula 2x2), pipeline híbrido 3D-Vectorial (Blender + Inkscape) para gráficos consistentes, y arquitectura modular asistida por IA/MCP en Godot.

---

## Índice de Documentación Modular

Para facilitar la lectura y desarrollo, la documentación está dividida en las siguientes áreas técnicas:

### [Gameplay y Mecánicas](gameplay/mecanicas_y_entidades.md)
- [Personaje y Habilidades](gameplay/personaje_y_habilidades.md): Atributos físicos, sprint con estamina, salto libre, plancha (*Dive*), linterna frontal y máquina de estados FSM.
- [Mapa y Sectores](gameplay/mapa_y_sectores.md): Topología 2x2, composición modular, límites físicos/visuales, corredores seguros ($160\text{ px}$) y matriz de colisiones.
- [Mecánicas y Entidades](gameplay/mecanicas_y_entidades.md): Core loop, jugador, IA y radios del monstruo, y bosque mutable.
- [Dificultad y Balance](gameplay/dificultad_y_balance.md): Progresión por notas, tabla cuantitativa de velocidades ($500 \to 920\text{ px/s}$) y reglas de mutación.
- [Sistema de Notas y Spawner](gameplay/sistema_de_notas_y_spawner.md): Jerarquía de `Area2D`, baliza luminosa, recolección atómica y algoritmo con filtros de distancia mínima.
- [Arquitectura de Partida y Director](gameplay/arquitectura_de_partida_y_director.md): Game Director (`maain.gd`), ciclo de señales, Game Over y persistencia de récords en Web.
- [Cámara y Game Feel](gameplay/camara_y_game_feel.md): Cámara $1:1$, sistema de sacudidas (*Shake*) por trauma acumulativo y post-procesamiento.

### [Arte y Pipeline Visual](arte/pipeline_hibrido.md)
- [Pipeline Híbrido](arte/pipeline_hibrido.md): Flujo paso a paso (Blender ➔ Inkscape ➔ Godot).
- [Guía de Estilo y Assets](arte/guia_estilo_y_assets.md): Estética visual y checklist de ~30 sprites necesarios.

### [Interfaz y Audio](interfaz_y_audio/controles_y_hud.md)
- [Controles y HUD](interfaz_y_audio/controles_y_hud.md): Entradas de teclado, HUD in-game, menú de pausa superpuesto en CanvasLayer 50, Game Over e integración de pantallas.
- [Audio y Feedback](interfaz_y_audio/audio_y_feedback.md): Paisaje sonoro, layout de buses de audio, radar de proximidad y efectos sensoriales.

### [Producción](produccion/roadmap_y_hitos.md)
- [Roadmap e Hitos](produccion/roadmap_y_hitos.md): Calendario de 4 semanas hacia Halloween, flujo de hitos y estado actual.
- [Backlog y Tareas](produccion/backlog_y_tareas.md): Desglose modular de tareas técnicas, de arte y de diseño con estados y criterios de aceptación.
- [Checklist de Exportación Web](produccion/checklist_exportacion_web.md): Parámetros para HTML5, resolución 1:1, IndexedDB, itch.io y Newgrounds en Godot 4.

### [Herramientas y Diagnóstico](herramientas/herramientas_de_debug.md)
- [Herramientas de Debug](herramientas/herramientas_de_debug.md): Menú unificado in-game (F3 tri-estado), telemetría de jugador/monstruo, diagnóstico de mutación para Issue #3, plugins de editor y MCP.
