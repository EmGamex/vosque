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
- [Mecánicas Generales y Core Loop](gameplay/mecanicas_y_entidades.md): Bucle principal, mapa sistémico de entidades y matriz de interacciones de colisión.
- [Personaje y Habilidades](gameplay/personaje_y_habilidades.md): Atributos físicos, sprint con estamina, salto libre, plancha (*Dive*), linterna frontal y máquina de estados FSM.
- [La Criatura (Monstruo) y su IA](gameplay/monstruo_e_ia.md): Ciclo de vida (hibernación en Nota 0 $\to$ despertar en Nota 1), cinemática, línea de visión, desatasco tangencial (*steering*) y detección letal.
- [Mapa y Sectores](gameplay/mapa_y_sectores.md): Topología 2x2 ($4320 \times 4320\text{ px}$), límites físicos/visuales perimetrales, corredores seguros ($160\text{ px}$) y diseño de variantes.
- [Sistema de Mutación y Niebla](gameplay/sistema_de_mutacion_y_niebla.md): Algoritmo dinámico de reemplazo de los 3 sectores lejanos, telón visual de niebla, exclusión mutua y optimizaciones WebGL.
- [Sistema de Iluminación](gameplay/sistema_de_iluminacion.md): Arquitectura de penumbra (Noche Americana), presupuesto WebGL 2.0 (2 luces reales), linterna procedural, halo aditivo y detección analítica del monstruo.
- [Sistema de Notas y Spawner](gameplay/sistema_de_notas_y_spawner.md): Jerarquía de `Area2D`, baliza luminosa, recolección atómica y algoritmo con filtros espaciales.
- [Dificultad y Balance](gameplay/dificultad_y_balance.md): Progresión por notas, tabla cuantitativa de velocidades ($500 \to 920\text{ px/s}$) y reglas de mutación.
- [Arquitectura de Partida y Director](gameplay/arquitectura_de_partida_y_director.md): Game Director (`maain.gd`), ciclo de señales, Game Over y persistencia de récords en Web.
- [Cámara y Game Feel](gameplay/camara_y_game_feel.md): Cámara $1:1$, sistema de sacudidas (*Shake*) por trauma acumulativo y post-procesamiento.

### [Interfaz y Audio](interfaz_y_audio/controles_y_hud.md)
- [Controles y HUD In-Game](interfaz_y_audio/controles_y_hud.md): Entradas de teclado, HUD minimalista en partida, barra de estamina y tutorial flotante sobre la cabeza.
- [Pantallas y Menús](interfaz_y_audio/pantallas_y_menus.md): Menú principal diegético con linterna en 1ª persona y parallax, menú de pausa (`CanvasLayer 50`) y pantalla de Game Over con jumpscare.
- [Gestor de Escenas y Ciclo de Vida](interfaz_y_audio/gestor_de_escenas.md): Patrón *Call Down, Signal Up*, control de `process_mode` y guía para integrar nuevas pantallas (Opciones/Créditos).
- [Audio y Feedback](interfaz_y_audio/audio_y_feedback.md): Paisaje sonoro, layout de buses de audio, radar de proximidad y efectos sensoriales.
- [Sistema de Música Interactiva](interfaz_y_audio/sistema_de_musica.md): Arquitectura de música, roles de pistas (`Night Crawling` y `Haunted Boardwalk`), sincronización rítmica, ducking dinámico y efecto Game Over.

### [Arte y Pipeline Visual](arte/pipeline_hibrido.md)
- [Pipeline Híbrido](arte/pipeline_hibrido.md): Flujo paso a paso (Blender ➔ Inkscape ➔ Godot).
- [Guía de Estilo y Assets](arte/guia_estilo_y_assets.md): Estética visual y checklist de ~30 sprites necesarios.

### [Producción](produccion/roadmap_y_hitos.md)
- [Estructura del Proyecto y Archivos](produccion/estructura_del_proyecto.md): Árbol oficial `res://`, convenciones de nomenclatura (`snake_case`), aislamiento de fuentes `.blend`/`.svg` (`.gdignore`) y gestión de carpetas de producción.
- [Roadmap e Hitos](produccion/roadmap_y_hitos.md): Calendario de 4 semanas hacia Halloween, flujo de hitos y estado actual.
- [Backlog y Tareas](produccion/backlog_y_tareas.md): Desglose modular de tareas técnicas, de arte y de diseño con estados y criterios de aceptación.
- [Checklist de Exportación Web](produccion/checklist_exportacion_web.md): Parámetros para HTML5, resolución 1:1, IndexedDB, itch.io y Newgrounds en Godot 4.

### [Herramientas y Diagnóstico](herramientas/herramientas_de_debug.md)
- [Herramientas de Debug](herramientas/herramientas_de_debug.md): Índice central del ecosistema de depuración.
- [Menú de Depuración In-Game](herramientas/menu_debug_ingame.md): Menú unificado F3 tri-estado, controladores modularizados, overlay vectorial en mundo y persistencia trans-sesión.
- [Plugins de Editor, MCP y Monitores](herramientas/plugins_editor_y_mcp.md): Toolbar de personaje (`addons/personaje_tools`), linter de variantes, MCP `godot_ai` y monitores nativos `Performance`.
- [Protocolos de Prueba y Diagnóstico](herramientas/protocolos_de_prueba.md): Guías de prueba paso a paso para validación de mutación (Issue #3), desatasco de IA y checklist para navegador Web.
