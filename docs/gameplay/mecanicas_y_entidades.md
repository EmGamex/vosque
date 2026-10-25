# Mecánicas Generales y Core Gameplay Loop

Este documento detalla el bucle principal de juego (*Core Gameplay Loop*), la interacción global entre las entidades del mundo y la arquitectura sistémica de **Vosque**.

---

## 1. Core Gameplay Loop

```mermaid
flowchart TD
    A([Inicio de Partida en Bosque]) --> B[Explorar en penumbra con linterna]
    B --> C{¿Encontró Nota?}
    C -- Sí --> D[+1 Puntuación & Sonido Inquietante]
    D --> E[Aumentar Velocidad del Monstruo]
    E --> F[Cerrar Niebla Radial & Mutar los 3 Sectores Lejanos]
    F --> G[Spawnear Nueva Nota en Sector Mutado & Abrir Niebla]
    G --> B
    C -- No --> H{¿Contacto con Monstruo?}
    H -- No --> B
    H -- Sí --> I([Game Over / Jumpscare])
    I --> J[Guardar High Score en Persistencia]
    J --> K[Reintentar Inmediato]
    K --> A
```

---

## 2. Mapa de Entidades y Documentación Especializada

Cada entidad de *Vosque* cuenta con un documento de diseño técnico dedicado donde se profundiza en su física, lógica de estados y jerarquía en motor:

| Entidad | Clase Base | Documento Especializado | Responsabilidad Principal |
| :--- | :--- | :--- | :--- |
| **Jugador** | `CharacterBody2D` | [Personaje y Habilidades](personaje_y_habilidades.md) | Movimiento en 8 direcciones, sprint con estamina, salto libre parabólico sobre obstáculos bajos, salto de plancha (*Dive*) y orientación de linterna. |
| **El Monstruo** | `CharacterBody2D` | [Monstruo e IA](monstruo_e_ia.md) | Amenaza perseguidora, hibernación en fase tutorial (Nota 0), despertar en Nota 1, desatasco tangencial (*steering*) y detección letal. |
| **Arena 2x2** | `Node2D` | [Mapa y Sectores](mapa_y_sectores.md) | Topología $4320 \times 4320\text{ px}$, vallas perimetrales fijas, límites de cámara, corredores seguros de $160\text{ px}$ y catálogo modular de variantes. |
| **Mutación Espacial** | `CanvasLayer` | [Sistema de Mutación y Niebla](sistema_de_mutacion_y_niebla.md) | Algoritmo procedural asíncrono, transición de iris de niebla, reemplazo atómico de 3 sectores y protocolo anti-atascamiento. |
| **Coleccionable** | `Area2D` | [Sistema de Notas y Spawner](sistema_de_notas_y_spawner.md) | Baliza luminosa, recolección atómica arcade sin pausas y algoritmo de aparición con filtros de exclusión mutua. |
| **Game Director** | `Node2D` | [Arquitectura de Partida y Director](arquitectura_de_partida_y_director.md) | Orquestación general de señales, flujo de inicio a fin de partida y persistencia del récord. |

---

## 3. Matriz de Interacciones y Capas de Colisión

La siguiente tabla resume cómo interactúan las entidades entre sí y con el entorno:

| Entidad | Mundo Alto (Capa 1) | Obstáculos Bajos (Capa 2) | Jugador (Capa 3) | Monstruo (Capa 4) | Interactuables (Capa 5) |
| :--- | :---: | :---: | :---: | :---: | :---: |
| **Jugador (Suelo)** | Bloquea | Bloquea | — | Muerte (Captura) | Recoge Nota |
| **Jugador (Salto/Dive)** | Bloquea | **Supera por arriba** (Inactiva) | — | Muerte (Captura) | Recoge Nota |
| **Monstruo (IA)** | Bloquea | **Bloquea** (Rodea) | Mata (`AreaCaptura`) | — | Ignora |
| **Nota Coleccionable** | Inerte | Inerte | Emite `recolectada` | Inerte | — |
| **Valla Perimetral** | Bloquea todo | — | Bloquea | Bloquea | — |

> [!TIP]
> **Ventaja Asimétrica del Salto:** La disparidad entre la máscara de colisión del jugador en el aire (Capa 2 inactiva) y la del monstruo (Capa 2 siempre activa) es la mecánica central de evasión del juego: permite al jugador ganar distancia saltando en línea recta sobre troncos caídos mientras el monstruo se ve forzado a rodearlos.

---

## 4. Filosofía de Juego: Tensión Arcade Ininterrumpida

1. **Sesiones Breves y Frenéticas:** Diseñado para partidas de 60 a 120 segundos donde el error se paga con la muerte inmediata.
2. **Cero Pantallas Bloqueantes en Partida:** Ni la recolección de notas ni la mutación espacial congelan el flujo de control del protagonista. La tensión de la persecución nunca se interrumpe.
3. **Reinicio Instantáneo:** La transición de Game Over a nueva partida se ejecuta en menos de un segundo presionando <kbd>Espacio</kbd> o <kbd>Enter</kbd>.
