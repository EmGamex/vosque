# Controles e Interfaz de Usuario (HUD)

Este documento especifica los esquemas de entrada para teclado en PC y las pantallas y elementos de la interfaz de usuario.

---

## 1. Esquema de Controles (PC / Teclado)

| Acción | Teclas Asignadas | Propósito |
| :--- | :--- | :--- |
| **Moverse Arriba** | `W` / `Flecha Arriba` | Desplazamiento vertical positivo |
| **Moverse Abajo** | `S` / `Flecha Abajo` | Desplazamiento vertical negativo |
| **Moverse Izquierda** | `A` / `Flecha Izquierda` | Desplazamiento horizontal negativo |
| **Moverse Derecha** | `D` / `Flecha Derecha` | Desplazamiento horizontal positivo |
| **Reintentar Partida** | `Espacio` / `Enter` / Clic en botón | Reinicio inmediato tras Game Over |

---

## 2. Elementos del HUD (En Partida)

* **Filosofía:** Minimalismo extremo para potenciar la inmersión y el miedo a la oscuridad.
* **Contador de Páginas:**
  - Posición: Esquina superior izquierda.
  - Formato: Texto simple y limpio (ejemplo: `Notas: 0`).
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
