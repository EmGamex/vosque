# Guía de Estilo y Lista de Assets

Este documento define la dirección artística, paleta de colores y el catálogo de recursos visuales requeridos para *Vosque*.

---

## 1. Dirección Artística
 
* **Tono Visual:** Terror arcade / Novela gráfica sombría con alto contraste.
* **Trazos:** Líneas negras gruesas y marcadas en los contornos, con rayado sutil para simular textura.
* **Modelo de Iluminación:** **Penumbra Contrastada (Noche Americana)**. En lugar de oscuridad ciega, se mantiene una base visible de tonos fríos para permitir lectura espacial rápida a $800 - 1000\text{ px/s}$.
* **Paleta de Color:**
  - Fondos y bosque: Azul petróleo oscuro (`#141824`), verdes musgo oscuros, tierras grisáceas y negros profundos.
  - Protagonista: Chubasquero / impermeable amarillo o crema reflectante (`#E5C158` / `#F0E6D2`) con contornos negros gruesos y linterna frontal. Este color cálido y brillante garantiza máximo contraste y legibilidad inmediata a alta velocidad sobre los fondos fríos y oscuros (`#141824`).
  - Criatura: Silueta grotesca oscura con ojos retro-reflectantes amarillo/rojo brillante.
  - Notas coleccionables: Papel blanco envejecido con halo luminoso propio y manchas de tinta/sangre.

---

## 2. Catálogo de Sprites (Checklist de Producción)

### 2.1. Protagonista (Pipeline Minimalista de 15 Frames)

Para maximizar la eficiencia y reducir el tiempo de dibujo a mano alzada en Inkscape, se adopta un enfoque de **perspectiva 3/4 simplificada a 3 direcciones con simetría horizontal y animación procedural en motor**:

| ID de Animación / Asset | Dirección / Pose | Cuadros | Resolución | Comportamiento / Optimización en Motor |
| :--- | :--- | :---: | :---: | :--- |
| `jugador_caminar_frente` | Frente / Hacia abajo | 4 | $128 \times 128$ px | Ciclo de paso regular en loop. |
| `jugador_caminar_perfil` | Lateral / Perfil | 4 | $128 \times 128$ px | Sirve para izquierda y derecha mediante volteo horizontal (`flip_h = true`). |
| `jugador_caminar_espalda` | Espalda / Hacia arriba | 4 | $128 \times 128$ px | Ciclo de paso regular en loop. |
| `jugador_salto_aire` | Pose de Salto Libre | 1 | $128 \times 128$ px | Pose estática con rodillas encogidas. El arco en el aire se anima en Godot alterando `position.y`. |
| `jugador_plancha_aire` | Pose de Plancha (*Dive*) | 1 | $128 \times 128$ px | Pose estática horizontal con brazos y piernas estiradas. |
| `jugador_suelo_recuperacion` | Caída y Recuperación | 1 | $128 \times 128$ px | Pose del personaje tendido boca abajo en la hojarasca durante los $0.6\text{ s}$ de vulnerabilidad. |
| `jugador_sombra` | Sombra Proyectada | 1 | $64 \times 32$ px | Óvalo negro con gradiente alfa suave en los pies; se escala inversamente en Godot al saltar. |
| **TOTAL CUADROS DIBUJADOS** | **Todo el Personaje** | **15** | — | **Ahorro de más del 75% frente a las 8 direcciones tradicionales.** |

#### Técnicas de Ahorro y Proceduralidad en Godot 4:
* **Sprint (Carrera):** No se dibujan cuadros nuevos; se acelera la reproducción del ciclo de caminar (`speed_scale = 1.6`) y se aplica una rotación leve de $5^\circ$ hacia adelante en el nodo del sprite.
* **Reposo (*Idle*):** Se usa el primer cuadro estático de la dirección correspondiente con un `Tween` sutil que modula la escala vertical (`scale.y` entre $0.97$ y $1.0$) simulando respiración agitada sin dibujar cuadros extra.
* **Pivote y Profundidad:** El origen del sprite se ubica en los pies (eje central inferior) para que el orden `y_sort_enabled` sea exacto respecto a los troncos y rocas.

### 2.2. La Criatura (Pipeline Ultra-Minimalista de 2 a 3 Cuadros)

Aprovechando que la lógica en `scripts/enemigo.gd` ya calcula la rotación continua hacia la velocidad (`_visual.rotation = velocity.angle()`), **no se dibujan direcciones adicionales**. Se dibuja en una única vista horizontal mirando a la derecha ($+X$, $0^\circ$) y Godot la orienta dinámicamente en $360^\circ$.

| ID de Animación / Asset | Descripción / Pose | Cuadros | Resolución | Comportamiento / Optimización en Motor |
| :--- | :--- | :---: | :---: | :--- |
| `monstruo_persecucion` | Bestia Cenital / Silueta grotesca mirando a $+X$ con garras frontales | 2–3 | $128 \times 128$ px | Ciclo alternado de zarpas/contracción muscular a 4–6 FPS. Godot lo rota automáticamente en $360^\circ$ hacia el jugador. |
| `monstruo_ojos_luz` | Máscara de ojos brillantes (amarillo/rojo) | — | — | Integrada en el sprite con material sin sombreado (`unshaded`) o acompañada de un pequeño `PointLight2D` rojo para destacar en penumbra total. |
| `monstruo_estela_humo` | Textura de partícula de humo/niebla oscura | 1 | $32 \times 32$ px | (Opcional) Partícula suave para `CPUParticles2D` que genera una estela de oscuridad al perseguir a alta velocidad. |
| **TOTAL CUADROS DIBUJADOS** | **Criatura Completa** | **2–3** | — | **Ahorro de más del 90% frente a un enemigo tradicional con 8 direcciones.** |

#### Técnicas de Ahorro y Dinámica de Terror en Godot 4:
* **Escalado de Fases sin Dibujar Más Sprites:** En la fase de *Cacería Frenética* (8+ notas), no se crea otro spritesheet; se incrementa el `speed_scale` de la animación a $2.0$ y se activa una oscilación sinoidal de escala (`Tween` elástico) junto con la emisión de partículas de humo negro.
* **Atmósfera de Sombras:** Menor detalle anatómico se traduce en mayor sensación de pánico y vulnerabilidad en la penumbra.

### 2.3. Menú Principal y Portada (Capas de Paralaje e Iluminación Diegética)

El Menú Principal recibe máxima prioridad visual como carta de presentación del juego y material promocional (*Key Art* para itch.io y Newgrounds). En lugar de una ilustración plana o un menú convencional, se compone en **6 capas en `res://graficos/menu principal/`** que generan un efecto de profundidad/paralaje cinematográfico e iluminación diegética por linterna en Godot:

| Capa / Asset | Descripción / Elementos | Resolución | Formato | Comportamiento en Godot 4 |
| :--- | :--- | :---: | :---: | :--- |
| `fondo degradado.jpg` | Fondo nocturno con degradado azul petróleo y cielo en el infinito | $1080 \times 1080$ px | JPG opaco | Parallax sutil ($8\%$) en `$Fondos/FondoDegradado`. |
| `montaña 2.png` | Silueta lejana de cordillera montañosa nocturna | $1080 \times 1080$ px | PNG transparente | Parallax intermedio ($22\%$) en `$Fondos/Montaña2`. |
| `montaña 1.png` | Silueta cercana de ladera con pinos y relieve rocoso | $1080 \times 1080$ px | PNG transparente | Parallax activo ($45\%$) tras los troncos en `$Fondos/Montaña1`. |
| `manu seleccion inicio.png` | Árbol central iluminado por haz de linterna (Opción **Jugar**) | $1080 \times 1080$ px | PNG transparente | Tronco y copa central iluminada; crossfade de alfa en `ArbolJugar`. |
| `variacion izquierda inicio.png` | Árbol izquierdo iluminado por haz de linterna (Opción **Opciones**) | $1080 \times 1080$ px | PNG transparente | Tronco y copa izquierda iluminada; crossfade de alfa en `ArbolOpciones`. |
| `variacion derecha inicio.png` | Árbol derecho iluminado por haz de linterna (Opción **Créditos**) | $1080 \times 1080$ px | PNG transparente | Tronco y copa derecha iluminada; crossfade de alfa en `ArbolCreditos`. |

### 2.4. Coleccionable Arcade (Dinámica Estilo Monedas)

Las notas coleccionables funcionan como **fichas/monedas arcade de recolección fluida**. Se elimina la necesidad de dibujar múltiples ilustraciones de páginas completas. La recolección es instantánea, sin pantallas de bloqueo que interrumpan el frenesí de la persecución:

| ID de Asset | Descripción | Resolución | Formato | Comportamiento en Godot 4 |
| :--- | :--- | :---: | :---: | :--- |
| `coleccionable_nota` | Página de papel viejo arrugada con bordes quemados y un símbolo críptico central en tinta negra | $64 \times 64$ px | PNG transparente | Flota verticalmente mediante un `Tween` senoidal (`position.y ± 6 px`) y rota levemente. |
| `coleccionable_halo` | Gradiente radial circular blanco/dorado suave | $128 \times 128$ px | PNG escala grises | Asignado a un `PointLight2D` para que la nota funcione como baliza visible en la penumbra. |
| `hud_icono_nota` | Miniatura simplificada de la nota para el contador | $32 \times 32$ px | PNG transparente | Se muestra junto al contador en el HUD superior izquierdo; pulsa al recoger una página. |

* **Feedback de Recolección en Motor:** Al cruzar el `Area2D`, se emite un sonido crujiente de papel/reliquia, un estallido breve de 8 partículas doradas/blancas (`CPUParticles2D`) y el contador numérico del HUD incrementa instantáneamente con un escalado elástico (`Tween` en `scale` $1.3 \to 1.0$), manteniendo al jugador en movimiento continuo.

### 2.5. Entorno y Bosque (Catálogo Modular de 5 Piezas)

Para poblar la arena completa de $4320 \times 4320\text{ px}$ (4 cuadrantes de $2160 \times 2160\text{ px}$) con variabilidad visual y mínimo esfuerzo de dibujo, se utilizan **5 sprites modulares** combinados con transformaciones en motor:

| ID de Asset | Tipo de Obstáculo | Capa de Colisión | Resolución | Técnicas de Reutilización en Godot 4 |
| :--- | :--- | :---: | :---: | :--- |
| `suelo_hojarasca_tile` | Terreno continuo | — | $256 \times 256$ px | Textura continua (*seamless* / repetible en mosaico). El `CanvasModulate` global le otorga el tono noche americana. |
| `arbol_frondoso` | Árbol denso con copa | Capa 1 (`Mundo_Alto`) | $256 \times 256$ px | Colisión circular en la base del tronco. Se aplican `flip_h`, variaciones de escala ($0.85$ a $1.20$) y modulación cromática sutil. |
| `arbol_seco` | Árbol retorcido muerto | Capa 1 (`Mundo_Alto`) | $256 \times 256$ px | Ofrece siluetas góticas y desoladas; se rota e invierte para romper patrones repetitivos. |
| `roca_asimetrica` | Peñasco de piedra musgosa | Capa 1 (`Mundo_Alto`) | $128 \times 128$ px | Diseñada deliberadamente asimétrica: al rotarse en $0^\circ, 90^\circ, 180^\circ$ y $270^\circ$, aparenta ser 4 rocas totalmente distintas. |
| `tronco_caido` | Tronco tumbado horizontal | Capa 2 (`Obstaculos_Bajos`) | $192 \times 64$ px | Obstáculo bajo para superar con el salto *Dive*. Puede orientarse horizontal o verticalmente. |
| `valla_alambre_tramo` | Tramo de valla de estacas | Capa 1 (`Mundo_Alto`) | $128 \times 64$ px | Módulo repetido a lo largo del perímetro exterior de $4320\text{ px}$ por lado. |

### 2.6. Pantallas de Impacto e Iluminación (Presupuesto WebGL 2.0)

> 💡 **Especificación completa:** Ver [Sistema de Iluminación](../gameplay/sistema_de_iluminacion.md) para fórmulas, detección de entidades y arquitectura de renderizado.

En el renderizador `gl_compatibility`, cada `PointLight2D` activo genera un pase adicional de renderizado sobre cada elemento en pantalla que intersecte su área. Para evitar la sobrecarga de fragmentos en Web:

* **Regla de 2 Luces Reales:** Solo se permiten un máximo de dos nodos `PointLight2D` activos simultáneos en el mundo: la **Linterna Frontal** del jugador y la **Baliza de la Nota** activa.
* **Linterna Frontal:** Un único nodo `PointLight2D` cónico con textura generada proceduralmente (o `luz_linterna_cono`) y **`shadow_enabled = false`** (sin sombras proyectadas dinámicas de 360°, las cuales son extremadamente costosas en WebGL).
* **Halos Secundarios Aditivos:** En lugar de múltiples nodos `PointLight2D`, el halo corporal del protagonista (`luz_halo_corporal`) se implementa mediante `Sprite2D` con material aditivo (`CanvasItemMaterial` en `BLEND_MODE_ADD`). Esto ofrece el mismo efecto visual de iluminación sobre la penumbra de `CanvasModulate` sin pases extras de luz en GPU.
* **Ojos Reflectantes:** Los ojos de la criatura usan `LIGHT_MODE_UNSHADED` en su material, brillando con total nitidez en la penumbra con coste computacional despreciable.

| ID de Asset | Descripción | Resolución | Comportamiento / Integración |
| :--- | :--- | :---: | :--- |
| `game_over_jumpscare` | Ilustración de alto impacto del rostro o garra de la bestia en tinta negra y rojo sangre | $512 \times 512$ px | Aparece instantáneamente en la pantalla de Game Over con sacudida brusca de pantalla (*camera shake*), estática y destello rojo estroboscópico. |
| `luz_linterna_cono` | Gradiente radial de cono angular para la linterna frontal (opcional / fallback procedural) | $512 \times 512$ px | Asignado al `PointLight2D` frontal del protagonista (sin sombras dinámicas). |
| `luz_halo_corporal` | Gradiente radial circular suave de penumbra | $256 \times 256$ px | Sprite aditivo (`BLEND_MODE_ADD`) centrado en el protagonista. |

---

## 3. Resumen Consolidado de Carga de Dibujo del Proyecto

| Categoría | Elementos Dibujados | Total Cuadros / Sprites |
| :--- | :--- | :---: |
| **Protagonista** | Caminar (3 vistas $\times$ 4 cuadros) + Salto (1) + Plancha (1) + Recuperación (1) + Sombra (1) | **15 cuadros** |
| **Criatura** | Silueta cenital en $+X$ (2 a 3 cuadros) | **2–3 cuadros** |
| **Menú Principal** | 3 Capas de fondo (cielo, montaña lejana, montaña cercana) + 3 Variaciones de iluminación de árboles | **6 capas** |
| **Entorno Modular** | Suelo tile + 2 Árboles + 1 Roca asimétrica + 1 Tronco caído + 1 Valla | **6 piezas** |
| **Coleccionable y HUD** | 1 Nota coleccionable + 1 Icono HUD | **2 piezas** |
| **Game Over** | 1 Ilustración jumpscare de impacto | **1 pieza** |
| **TOTAL ABSOLUTO DE TODO EL JUEGO** | **Todas las animaciones, menús, mapas y entidades** | **~32 a 33 piezas/cuadros** |

> [!TIP]
> **Eficiencia Máxima de Producción:** Con menos de 30 piezas gráficas en total, el juego completo dispone de gráficos propios de autor, coherencia estética tenebrosa y cero elementos "cutrillos", apoyándose en la iluminación 2D, shaders y físicas de Godot 4 para toda la riqueza visual.

