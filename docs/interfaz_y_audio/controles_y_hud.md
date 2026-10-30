# Controles e Interfaz de Usuario (HUD)

Este documento especifica los esquemas de entrada para teclado en PC, los elementos visuales del HUD durante la partida y el sistema de onboarding interactivo (tutorial flotante) de **Vosque**.

> 🎮 **Pantallas y menús:** [Pantallas y Menús](../interfaz_y_audio/pantallas_y_menus.md)  
> 🏛️ **Arquitectura de navegación:** [Gestor de Escenas y Ciclo de Vida](../interfaz_y_audio/gestor_de_escenas.md)

---

## 1. Esquema de Controles (PC / Teclado y Ratón Opcional)

| Acción | Teclas / Entradas Asignadas | Propósito |
| :--- | :--- | :--- |
| **Moverse Arriba** | <kbd>W</kbd> / <kbd>↑</kbd> | Desplazamiento vertical hacia arriba ($-Y$) |
| **Moverse Abajo** | <kbd>S</kbd> / <kbd>↓</kbd> | Desplazamiento vertical hacia abajo ($+Y$) |
| **Moverse Izquierda** | <kbd>A</kbd> / <kbd>←</kbd> | Desplazamiento horizontal a la izquierda ($-X$) |
| **Moverse Derecha** | <kbd>D</kbd> / <kbd>→</kbd> | Desplazamiento horizontal a la derecha ($+X$) |
| **Sprint (Correr)** | <kbd>Shift</kbd> | Aceleración temporal continua consumiendo la barra de estamina |
| **Salto / Plancha (*Dive*)** | <kbd>Espacio</kbd> | Salto en suelo; segunda pulsación en el aire ejecuta plancha hacia adelante con caída e inmovilidad de recuperación. En el menú de pausa y menú principal, confirma la opción seleccionada. |
| **Pausar / Reanudar** | <kbd>Escape</kbd> / <kbd>P</kbd> (`pausa` / `ui_cancel`) | Alterna el menú de pausa superpuesto en partida activa mediante congelación híbrida del `SceneTree`. En el menú de pausa se puede navegar con <kbd>W</kbd>/<kbd>S</kbd> y confirmar con <kbd>Espacio</kbd>. Si la consola F3 está abierta, <kbd>Escape</kbd> cierra primero el debug. |
| **Orientar Linterna** | *Movimiento del Ratón* / *Automático* | Apunta al cursor si se usa el ratón, o sigue la dirección de marcha si se juega solo con teclado |
| **Reintentar Partida** | <kbd>Espacio</kbd> / <kbd>Enter</kbd> / Clic en botón | Reinicio inmediato tras Game Over o desde el menú de pausa |
| **Panel de Depuración** | <kbd>F3</kbd> | Alterna el ciclo tri-estado de depuración (Oculto $\to$ Mini-HUD $\to$ Menú Completo) |

---

## 2. Elementos del HUD (En Partida)

* **Filosofía:** Minimalismo extremo y ritmo arcade puro para potenciar la inmersión y el miedo a la oscuridad sin obstrucciones visuales.
* **Contador de Coleccionables (Notas):**
  - Posición: Esquina superior izquierda (`Vector2(32, 32)`).
  - Componentes: Icono vectorial simple de página (`hud_icono_nota`, $32 \times 32$ px) seguido del valor numérico con tipografía limpia y de alto contraste (ejemplo: `x 0`).
  - Animación de Recogida: Al tomar una nota, el contador realiza un salto de escala elástico mediante un `Tween` (`scale` $1.3 \to 1.0$ en $0.25\text{ s}$) y un breve destello blanco.
* **Indicador Diegético de Estamina (Resistencia):**
  - Componente circular procedural anclado a la cabeza del personaje (`Vector2(0, -60)`).
  - Anillo radial nítido dibujado proceduralmente con `_draw()` (`draw_arc`).
  - Totalmente invisible en reposo (100% estamina); aparece con fade-in y micro-pop ($0.8 \to 1.0$) al consumir energía.
  - Paleta semántica: Ámbar cálido (`#E5A93C`) en régimen normal y titileo intermitente en carmesí (`#D13438`) durante fatiga o umbral crítico ($< 30\%$).
  - Animación de cierre al recargar al 100%: destello blanco-dorado, pulso elástico ($1.0 \to 1.2 \to 1.0$ en $0.2\text{ s}$) y fade-out suave a alfa 0.0 en $0.3\text{ s}$.
* **Feedback de Recolección Arcade (Sin Pausas ni Flashes Bloqueantes):**
  - Al hacer contacto con el `Area2D` de la nota, la recolección es **inmediata y desatendida** (estilo moneda o reliquia arcade).
  - El jugador no sufre parones, ni se abre ninguna ilustración que le tape la pantalla.
  - Efectos simultáneos en el instante de contacto:
    1. **Audio:** Sonido seco y crujiente de papel antiguo desgarrado.
    2. **Partículas:** Brote radial de 8 a 10 partículas diminutas de polvo blanco/dorado (`CPUParticles2D`) en el punto del mapa donde estaba la nota.
    3. **HUD:** Incremento del contador numérico con el pulso elástico del icono.
    4. **Comportamiento del Monstruo:** La criatura recibe la señal de aceleración de fase (ver [Dificultad y Balance](../gameplay/dificultad_y_balance.md)) sin interrumpir la persecución activa.

---

## 3. Tutorial Flotante sobre la Cabeza del Personaje (Onboarding In-Game)

Para garantizar un onboarding inmediato que no rompa la inmersión cenital ni requiera pausas artificiales, al iniciar cada partida aparece un indicador flotante diegético centrado en la cabeza del personaje (`Vector2(0, -90)`):

### 3.1. Estructura Visual
* **Contenedor:** Pastilla flotante con fondo negro translúcido (`Color(0.08, 0.10, 0.15, 0.85)`), esquinas redondeadas y borde sutil.
* **Badges de Teclas:** Representaciones visuales de teclas estilizadas con contraste alto.

### 3.2. Secuencia de 3 Pasos
1. **Paso 1: Locomoción en 4 Direcciones:**
   - Mensaje: `"Mueve con [W] [A] [S] [D]"` (o flechas).
   - Comportamiento: A medida que el jugador presiona cada dirección, el badge de esa tecla se ilumina en ámbar/verde (`#4ade80`).
   - Criterio de avance: Haber presionado las 4 direcciones (o alcanzar desplazamiento sostenido).
2. **Paso 2: Superación de Obstáculos Bajos (Salto):**
   - Mensaje: `"Presiona [Espacio] para saltar"`.
   - Criterio de avance: Detectar `personaje-salto` y la transición al estado `SALTO`.
3. **Paso 3: Aceleración con Estamina (Sprint):**
   - Mensaje: `"Mantén presionado [Shift] para correr"`.
   - Criterio de avance: Sostener la acción `sprint` y transicionar a `SPRINT`.
   - Cierre: Al activarse el sprint, la pastilla reproduce un pulso de confirmación y se desvanece suavemente con un `Tween` de alfa en $0.4\text{ s}$ antes de liberarse.

### 3.3. Protocolo de Desvanecimiento Forzado
* Si el jugador se dirige directamente a la primera nota y la recolecta antes de completar los 3 pasos, el tutorial se desvanece instantáneamente para no entorpecer la cacería de la criatura.

### 3.4. Zona Segura Inicial (Ausencia de Monstruo en Nota 0)
* Durante toda la fase de tutorial (Nota 0), el monstruo no está presente físicamente ni visible en el escenario.
* El nodo del monstruo se mantiene en **hibernación completa** (`visible = false`, `process_mode = Node.PROCESS_MODE_DISABLED` fuera de pantalla), despertando únicamente cuando se recoge la primera página (ver [Monstruo e IA](../gameplay/monstruo_e_ia.md)).
