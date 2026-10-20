# Estructura del Proyecto y Convenciones de Archivos

Este documento establece la arquitectura oficial del árbol de directorios de Godot 4 (`res://`), las convenciones de nomenclatura y las reglas de gestión de assets para garantizar el orden y la eficiencia en la producción de **Vosque**.

---

## 1. Árbol de Directorios Oficial (`res://`)

```text
c:/Proyectos/vosque/
├── .agents/                    # Configuraciones, prompts y skills de pair programming con agentes IA
├── addons/                     # Plugins y extensiones del motor Godot
│   ├── godot_ai/               # Servidor de integración MCP / IA para inspección en vivo
│   └── personaje_tools/        # Toolbar contextual en 2D para calibración cinemática
├── assets_raw/                 # Archivos fuente editables de diseño (IGNORADOS por Godot con .gdignore)
│   ├── blender/                # Modelos 3D base y escenas de cámara ortográfica (.blend)
│   └── inkscape/               # Proyectos vectoriales de entintado y color (.svg)
├── audio/                      # Recursos sonoros y buses del juego (Semanas 3-4)
│   ├── ambiente/               # Loops de viento, crujidos y ruidos nocturnos (.ogg)
│   ├── criatura/               # SFX del monstruo, zumbido de estática y jumpscare (.wav / .ogg)
│   ├── jugador/                # Pisadas, esfuerzo de salto, impacto y respiración (.wav)
│   ├── interfaz/               # Clics de botones, rasgado de papel de nota (.wav)
│   └── default_bus_layout.tres # Configuración de los 4 buses de audio
├── docs/                       # Documentación técnica, diseño (GDD) y producción
├── escenas/                    # Escenas empaquetadas (.tscn)
│   ├── efectos/                # Efectos visuales independientes (niebla_mutacion.tscn, etc.)
│   ├── obstaculos/             # Prefabs de colisión del mundo (arbol.tscn, roca.tscn, tronco_bajo.tscn)
│   ├── sectores/               # Infraestructura modular de cuadrantes
│   │   └── variantes/          # Sub-escenas de variantes 2160x2160 (variante_bosque_denso.tscn, etc.)
│   ├── ui/                     # Menús e interfaz (menu_inicio.tscn, menu_pausa.tscn, hud.tscn, game_over.tscn)
│   ├── camara.tscn             # Cámara 2D con suavizado y trauma shake
│   ├── debug_menu.tscn         # Menú unificado de depuración in-game (F3)
│   ├── enemigo.tscn            # Criatura perseguidora
│   ├── escenario.tscn          # Arena 2x2, valla perimetral y orquestador de mutación
│   ├── gestor_escenas.tscn     # Escena raíz principal con transiciones entre pantallas
│   ├── maain.tscn              # Escena del mundo activo (Game Director)
│   ├── nota.tscn               # Coleccionable arcade baliza
│   └── personaje.tscn          # Protagonista
├── graficos/                   # Texturas y sprites importados (.png)
│   ├── bocetos/                # Graybox y bocetos provisionales de prototipado
│   ├── criatura/               # Sprites finales de la criatura cenital y ojos
│   ├── entorno/                # Tiles de suelo, árboles, rocas, troncos y valla
│   ├── interfaz/               # Iconos HUD, badges de tutorial, logos y portada
│   ├── jumpscare/              # Ilustración de impacto de Game Over (512x512)
│   ├── notas/                  # Sprite de hoja arrugada y halo
│   └── personaje/              # Spritesheets y poses de caminar, salto, plancha y sombra
├── recursos/                   # Recursos serializados de Godot (.tres)
│   ├── materiales/             # Shaders materials (mat_niebla_mutacion.tres, etc.)
│   ├── temas/                  # Estilos visuales de UI y botones (StyleBoxFlat, fuentes)
│   └── tilesets/               # Tileset de obstáculos y suelo (tileset_obstaculos.tres, etc.)
├── scripts/                    # Código fuente GDScript (.gd)
│   ├── debug_menu/             # Controladores modulares del menú F3 (cheats, física, escenario, etc.)
│   ├── debug_config.gd         # Singleton/Autoload de persistencia de ajustes de debug
│   ├── efecto_niebla_mutacion.gd # Lógica de iris y ceguera de transición
│   ├── enemigo.gd              # IA de persecución, rotación y anti-atascamiento
│   ├── escenario.gd            # Mutación de sectores lejanos y reubicación segura
│   ├── game_over.gd            # Lógica de fin de partida y récord
│   ├── gestor_escenas.gd       # Máquina de estados de pantallas y transiciones
│   ├── menu_inicio.gd          # Menú principal y paralaje con ratón
│   ├── menu_pausa.gd           # Control de pausa en CanvasLayer 50
│   ├── nota.gd                 # Recolección atómica de páginas
│   └── personaje.gd            # FSM de locomoción, estamina, salto y plancha
├── shaders/                    # Archivos de sombreadores en tiempo real (.gdshader)
├── tests/                      # Scripts y suites de pruebas automatizadas (.gd)
├── export_presets.cfg          # Configuración de exportación (WebGL Compatibility, threads=false)
└── project.godot               # Archivo maestro de configuración del proyecto
```

---

## 2. Convenciones de Nomenclatura

Para evitar errores en plataformas sensibles a mayúsculas/minúsculas (Linux, exportación Web/WASM) y mantener consistencia absoluta:

1. **Formato Estándar:** Usar **estrictamente `snake_case` en minúsculas** para todos los archivos y carpetas:
   - ✅ Correcto: `variante_bosque_denso.tscn`, `personaje_caminar_frente.png`, `mat_niebla.tres`.
   - ❌ Incorrecto: `abajo boceto.png`, `VarianteBosque.tscn`, `Menu_Pausa.TSCN`.
2. **Prefijos Descriptivos Recomendados:**
   - Shaders y Materiales: Prefijo `mat_` para `.tres` (ej. `mat_niebla_mutacion.tres`) y nombre temático para `.gdshader` (ej. `niebla_mutacion.gdshader`).
   - Variantes de Mapa: Prefijo `variante_` (ej. `variante_claro_rocoso.tscn`).
   - Tests de Unidad: Prefijo `test_` (ej. `test_escenario.gd`).
3. **Clases GDScript (`class_name`):**
   - Usar **`PascalCase`** (ej. `class_name Personaje`, `class_name DebugMenu`, `class_name Escenario`).

---

## 3. Manejo de Archivos Fuente Crudos (`.gdignore`)

Para que los modelos de Blender (`.blend`, `.blend1`) y los archivos vectoriales multicapa de Inkscape (`.svg`) se almacenen dentro del repositorio sin que el motor Godot intente importarlos, compilarlos o empaquetarlos en el build Web:

* Todo el material editable se aloja en la carpeta `assets_raw/`.
* Se coloca un archivo vacío nombrado **`.gdignore`** en la raíz de `assets_raw/`:
  ```text
  c:/Proyectos/vosque/assets_raw/.gdignore
  ```
* **Efecto:** Godot 4 ignora completamente este directorio durante la indexación de recursos y exportación HTML5, manteniendo el paquete `.pck` ligero y optimizado.

---

## 4. Clasificación y Separación de Recursos

* **No mezclar recursos `.tres` en carpetas de escenas:** Los archivos de estilo o configuración (`debug_key_bg.tres`, `debug_center_bg.tres`) deben residir en `recursos/temas/` o junto a sus componentes de interfaz correspondientes.
* **Separación de Gráficos de Producción vs. Bocetos:** Los bocetos originales del prototipo se conservan en `graficos/bocetos/`, mientras que los assets finales del pipeline de 30 piezas se exportan a sus subcarpetas temáticas (`graficos/personaje/`, `graficos/entorno/`, etc.).
* **Archivos Huérfanos o Backups en la Raíz:** Carpetas de empaquetado temporal o backups como `vosque-proyecto/` o archivos `.zip` deben ubicarse fuera del árbol de desarrollo o agregarse a `.gitignore`.
