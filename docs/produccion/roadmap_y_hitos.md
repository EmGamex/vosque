# Roadmap e Hitos de Producción

Este documento detalla el cronograma de desarrollo acotado a 4 semanas para alcanzar el objetivo de lanzamiento en Halloween (31 de Octubre de 2026), reflejando el progreso técnico real del proyecto a fecha de **25 de Octubre de 2026**.

---

## 1. Visión Temporal y Flujo de Hitos (4 Semanas)

```mermaid
flowchart TD
    subgraph S1 ["Semana 1 (04/10 - 10/10): Prototipo Graybox [100%]"]
        W1A["Movimiento 8-Dir + Telemetría F3"] --> W1B["Plugin de Editor personaje_tools"]
        W1B --> W1C["Gestor de Escenas, Menús y Transiciones"]
        W1C --> W1D["IA Base del Monstruo con Rotación Continua"]
    end

    subgraph S2 ["Semana 2 (11/10 - 17/10): Mecánicas Evasivas y GDD Técnico [100%]"]
        W2A["GDD: Salto Libre y Salto de Plancha (Dive)"] --> W2B["GDD: Sistema de Estamina y Fatiga"]
        W2B --> W2C["GDD: Arena 2x2 y Sectores Mutables"]
        W2C --> W2D["GDD: Sistema de Notas, Director, Audio y Cámara"]
        W2D --> W2E["Catálogo Artístico de ~30 Assets"]
    end

    subgraph S3 ["Semana 3 (18/10 - 24/10): Integración en Motor y Web [COMPLETADA]"]
        W3A["Implementación de Salto, Plancha y Estamina"] --> W3B["Sectores Mutables 2x2 y Corredores Seguros"]
        W3B --> W3C["Spawner de Notas Baliza y Escalado Cuantitativo"]
        W3C --> W3D["Director maain.gd, Condición Derrota y Preset Web"]
    end

    subgraph S4 ["Semana 4 (25/10 - 31/10): HUD, Arte Final, Audio y Lanzamiento [EN CURSO]"]
        W4A["HUD In-Game, Linterna y Menú de Pausa"] --> W4B["Producción de Sprites Finales (Blender + Inkscape)"]
        W4B --> W4C["Integración de SFX, Gestor de Música y Trauma Shake"]
        W4C --> W4D["Persistencia High Score y Publicación (itch.io / Newgrounds)"]
    end

    S1 --> S2
    S2 --> S3
    S3 --> S4

    classDef done fill:#2d4a22,stroke:#529e3a,color:#ffffff;
    classDef current fill:#5a451b,stroke:#e69f0c,color:#ffffff;
    classDef pending fill:#1f2430,stroke:#4f5b66,color:#c0c5ce;

    class W1A,W1B,W1C,W1D,W2A,W2B,W2C,W2D,W2E,W3A,W3B,W3C,W3D done;
    class W4A,W4B,W4C,W4D current;
```

---

## 2. Estado de Producción por Semana

### Semana 1 (04/10/2026 – 10/10/2026): Base Funcional (Graybox) — **[100% COMPLETADA]**
* **Objetivo:** Establecer la base de físicas, cámara, ciclo de pantallas y herramientas del desarrollador.
* **Entregables Concluidos:**
  - [x] Movimiento fluido en 8 direcciones con aceleración (`5000 px/s²`), fricción y freno seco (`stop_threshold = 15.0 px/s`) en [`personaje.gd`](../../scripts/personaje.gd).
  - [x] Suavizado y centrado dinámico de [`camara.tscn`](../../escenas/camara.tscn).
  - [x] HUD de telemetría en tiempo real [`debug_info.gd`](../../scripts/debug_info.gd) con alternancia vía tecla `F3`.
  - [x] Plugin de editor contextual [`addons/personaje_tools`](../../addons/personaje_tools) para calibración de presets (`Sigilo`, `Normal`, `Sprint`).
  - [x] Arquitectura de ciclo de juego [`gestor_escenas.gd`](../../scripts/gestor_escenas.gd) con transiciones por fundido a negro entre [`menu_inicio.tscn`](../../escenas/menu_inicio.tscn), [`maain.tscn`](../../escenas/maain.tscn) y [`game_over.tscn`](../../escenas/game_over.tscn).
  - [x] IA elemental de persecución con cálculo vectorial y rotación visual continua hacia el jugador en [`enemigo.gd`](../../scripts/enemigo.gd).

---

### Semana 2 (11/10/2026 – 17/10/2026): Especificación Técnica y Mecánicas Evasivas — **[100% COMPLETADA]**
* **Objetivo:** Formalizar el GDD modular, diseñar habilidades de evasión arcade de alto riesgo, delimitar el mapa modular, especificar los subsistemas clave (Notas, Spawner, Game Director, Audio y Cámara) y definir el pipeline artístico óptimo de 30 piezas.
* **Entregables:**
  - [x] Especificación técnica de **Salto Libre** (arco Z simulado en $0.45\text{ s}$ superando obstáculos bajos) y **Salto de Plancha (*Dive*)** con vulnerabilidad de $0.6\text{ s}$ en suelo en [`personaje_y_habilidades.md`](../gameplay/personaje_y_habilidades.md).
  - [x] Especificación de **Sprint y Barra de Estamina** nativa con retardo de recarga de $0.8\text{ s}$ y umbral de seguridad de fatiga ($30\%$).
  - [x] Diseño topológico de la **Arena 2x2 ($4320 \times 4320$ px con cuadrantes de $2160 \times 2160$ px)**, sub-escenas de variantes, franjas seguras de $160\text{ px}$ en intersecciones y algoritmo de mutación de los 3 sectores lejanos en [`mapa_y_sectores.md`](../gameplay/mapa_y_sectores.md).
  - [x] Matriz de capas de física (Capa 1: `Mundo_Alto`, Capa 2: `Obstaculos_Bajos`, Capa 3: `Jugador`, Capa 4: `Monstruo`, Capa 5: `Interactuables`).
  - [x] Especificación técnica de **Sistema de Notas y Spawner** con filtros espaciales ($R_{\min} \ge 600\text{ px}$) y baliza luminosa en [`sistema_de_notas_y_spawner.md`](../gameplay/sistema_de_notas_y_spawner.md).
  - [x] Diseño de arquitectura de partida y Game Director con persistencia dual de *High Score* en [`arquitectura_de_partida_y_director.md`](../gameplay/arquitectura_de_partida_y_director.md).
  - [x] Especificación de **Cámara y Game Feel** con modelo de sacudida por trauma cuadrático ($T^2$) en [`camara_y_game_feel.md`](../gameplay/camara_y_game_feel.md).
  - [x] Catálogo consolidado de arte de ~30 piezas en [`guia_estilo_y_assets.md`](../arte/guia_estilo_y_assets.md).
  - [x] Diseño de arquitectura del **Menú de Pausa** como `CanvasLayer` en `layer=50` en [`controles_y_hud.md`](../interfaz_y_audio/controles_y_hud.md).

---

### Semana 3 (18/10/2026 – 24/10/2026): Integración en Motor, Mutación 2x2 y Web — **[100% COMPLETADA]**
* **Objetivo:** Trasladar las mecánicas documentadas al código GDScript de Godot 4, habilitar la mutación continua de cuadrantes y validar la primera compilación funcional en navegador.
* **Entregables Clave:**
  - [x] Implementar la máquina de estados de Salto Libre, Plancha (*Dive*) y simulación de elevación en eje Z en [`personaje.gd`](../../scripts/personaje.gd).
  - [x] Implementar la lógica de Estamina y fatiga en [`personaje.gd`](../../scripts/personaje.gd).
  - [x] Crear la estructura modular de [`escenas/escenario.tscn`](../../escenas/escenario.tscn) con valla perimetral fija y las sub-escenas de variantes con corredores de paso seguros.
  - [x] Programar la lógica de mutación de los 3 sectores lejanos, niebla de transición (`EfectoNieblaMutacion`) y reposicionamiento anti-atascamiento del monstruo.
  - [x] Crear la entidad coleccionable [`escenas/nota.tscn`](../../escenas/nota.tscn) con baliza luminosa y recolección arcade instantánea.
  - [x] Implementar el orquestador Game Director en [`scripts/maain.gd`](../../scripts/maain.gd) conectando las señales de recolección, mutación y el algoritmo de Spawner con exclusión espacial.
  - [x] Implementar el escalado de velocidad del enemigo según el modelo cuantitativo acotado ($500 \to 920\text{ px/s}$) y condición de derrota hacia Game Over en [`enemigo.gd`](../../scripts/enemigo.gd).
  - [x] Implementar suite de telemetría y menú unificado de diagnóstico in-game en [`escenas/debug_menu.tscn`](../../escenas/debug_menu.tscn).
  - [x] Configurar preset de exportación Web en [`export_presets.cfg`](../../export_presets.cfg) y preparar flags de compatibilidad navegador.

---

### Semana 4 (25/10/2026 – 31/10/2026): HUD, Arte Final, Audio, Pulido y Lanzamiento — **[EN CURSO - FALTAN 6 DÍAS]**
* **Objetivo:** Conectar el feedback de usuario (HUD, pausa, linterna), sustituir placeholders por assets clave, orquestar música interactiva y SFX, configurar High Score y publicar para Halloween.
* **Entregables Clave:**
  - [ ] Diseñar el HUD in-game (`hud.tscn`) con `ProgressBar` nativo vinculado a `estamina_cambiada` y contador numérico elástico de notas.
  - [ ] Implementar la linterna frontal desacoplada del personaje (halo radial + haz orientable 360° / movimiento).
  - [ ] Integrar el Menú de Pausa (`escenas/menu_pausa.tscn`, `CanvasLayer`, `layer=50`) con congelación híbrida blindada (`SceneTree.paused` + `PROCESS_MODE_ALWAYS` en UI/orquestador), salvaguarda anti-salto y soporte Escape/P.
  - [ ] Generar los renders 3D base en Blender y vectorizar en Inkscape los sprites prioritarios del jugador (15 frames) y criatura (silueta + ojos emisivos).
  - [ ] Configurar el Singleton Autoload `GestorMusica` con crossfade dinámico de pistas existentes (`Night Crawling` $\to$ `Haunted Boardwalk`) y buses de audio.
  - [ ] Implementar el sistema de trauma shake en [`camara.tscn`](../../escenas/camara.tscn) (impacto de plancha y muerte).
  - [ ] Implementar persistencia de High Score en Web (`user://` sobre `IndexedDB` y fallback a `localStorage`).
  - [ ] Pulir pantalla de Game Over con comparativa de récord.
  - [ ] Probar compatibilidad en navegadores principales (Chrome, Firefox, Edge).
  - [ ] Diseñar portada promocional (*Key Art*), banners y capturas.
  - [ ] Publicar y verificar el juego en Newgrounds e itch.io el **31 de Octubre de 2026**.

---

## 3. Matriz de Riesgos y Mitigaciones

| Riesgo Identificado | Impacto | Probabilidad | Estrategia de Mitigación |
| :--- | :---: | :---: | :--- |
| **Cuello de botella en dibujo de sprites** | Alto | Media | Catálogo congelado a un máximo estricto de ~30 piezas; uso de animación procedural (escala de respiración, aceleración de ciclo para sprint, rotación matemática 360° del monstruo). |
| **Problemas de CORS/COOP en Web** | Crítico | Media | Mantener hilos desactivados (`threads = false`) en el preset Web; de este modo el juego corre en cualquier iframe sin requerir cabeceras HTTP especiales en itch.io/Newgrounds. |
| **Atascamiento del monstruo al mutar** | Alto | Baja | Algoritmo anti-atascamiento con `test_move()`, reubicando a la criatura al `Marker2D` libre más cercano y excluyéndolo del sorteo de la nueva nota. |
| **Pérdida de foco del teclado en iframe** | Medio | Alta | Script en contenedor HTML (`canvas.focus()`) y anulación de propagación de teclas (`preventDefault` para Espacio y Flechas). |
