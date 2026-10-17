# Controles e Interfaz de Usuario (HUD)

Este documento especifica los esquemas de entrada para teclado en PC y las pantallas y elementos de la interfaz de usuario.

---

## 1. Esquema de Controles (PC / Teclado y Ratón Opcional)

| Acción | Teclas / Entradas Asignadas | Propósito |
| :--- | :--- | :--- |
| **Moverse Arriba** | `W` / `Flecha Arriba` | Desplazamiento vertical hacia arriba ($-Y$) |
| **Moverse Abajo** | `S` / `Flecha Abajo` | Desplazamiento vertical hacia abajo ($+Y$) |
| **Moverse Izquierda** | `A` / `Flecha Izquierda` | Desplazamiento horizontal a la izquierda ($-X$) |
| **Moverse Derecha** | `D` / `Flecha Derecha` | Desplazamiento horizontal a la derecha ($+X$) |
| **Sprint (Correr)** | `Shift` | Aceleración temporal continua consumiendo la barra de estamina |
| **Salto / Plancha (*Dive*)** | `Espacio` | Salto en suelo; segunda pulsación en el aire ejecuta plancha hacia adelante con caída e inmovilidad de recuperación |
| **Orientar Linterna** | *Movimiento del Ratón* / *Automático* | Apunta al cursor si se usa el ratón, o sigue la dirección de marcha si se juega solo con teclado |
| **Reintentar Partida** | `Espacio` / `Enter` / Clic en botón | Reinicio inmediato tras Game Over |
| **Panel de Depuración** | `F3` | Alterna la visibilidad de la telemetría de físicas y dirección |

---

## 2. Elementos del HUD (En Partida)

* **Filosofía:** Minimalismo extremo para potenciar la inmersión y el miedo a la oscuridad.
* **Contador de Páginas:**
  - Posición: Esquina superior izquierda.
  - Formato: Texto simple y limpio (ejemplo: `Notas: 0`).
* **Barra de Estamina (Resistencia):**
  - Indicador visual discreto que muestra la reserva de energía disponible para la habilidad de **Sprint** (ver [Personaje y Habilidades](../gameplay/personaje_y_habilidades.md)).
  - Disminuye al correr y se recarga gradualmente al caminar o detenerse; cambia de color o parpadea si entra en estado de agotamiento (*Fatiga*).
* **Flash de Nota (Feedback de Recolección):**
  - Al recoger una página, se muestra una ilustración o texto perturbador en el centro de la pantalla durante **1 segundo exacto**.
  - **No pausa el juego:** La criatura sigue desplazándose durante este segundo, elevando el pánico del jugador.

---

## 3. Pantalla de Game Over

Aparece de forma inmediata tras el contacto con el monstruo:
1. **Arte de Impacto:** Ilustración de jumpscare/derrota en estilo cómic oscuro o estática roja.
2. **Resultados de la Partida:**
   - Páginas recogidas en la sesión actual.
   - Récord histórico (*High Score* persistido en `LocalStorage` vía JavaScript / Web).
3. **Acción Rápida:** Botón llamativo de "Reintentar" y soporte para presionar `Espacio` para reiniciar la partida en menos de 1 segundo.
