# Mapa y Topología de Sectores

Este documento detalla la topología espacial, la delimitación física/visual perimetral, la arquitectura modular de variantes y las reglas de diseño para la arena de **Vosque**.

> 💻 **Escena maestra:** [`escenas/escenario.tscn`](../../escenas/escenario.tscn)  
> 💻 **Script de orquestación:** [`scripts/escenario.gd`](../../scripts/escenario.gd)  
> 🌀 **Algoritmo de mutación y niebla:** [Sistema de Mutación y Niebla](sistema_de_mutacion_y_niebla.md)

---

## 1. Topología y Coordenadas del Mundo

La arena de juego de *Vosque* es un espacio cerrado continuo de **$4320 \times 4320\text{ px}$** organizado en una cuadrícula $2 \times 2$ simétrica respecto al origen global `(0, 0)`:

```
                  -2160 Y (Límite Norte)
            ┌───────────────────┬───────────────────┐
            │                   │                   │
            │     Sector NO     │     Sector NE     │
            │ Pivote:(-1080,-1080) Pivote:(1080,-1080)│
            │                   │                   │
 -2160 X ───┼───────────────────┼───────────────────┼─── +2160 X
 (Límite    │                   │                   │   (Límite
  Oeste)    │     Sector SO     │     Sector SE     │    Este)
            │ Pivote:(-1080,1080)  Pivote:(1080,1080) │
            │                   │                   │
            └───────────────────┴───────────────────┘
                  +2160 Y (Límite Sur)
```

### Tabla de Cuadrantes

| Cuadrante | Rango Coordenadas $X$ | Rango Coordenadas $Y$ | Coordenada Local Pivote | Dimensiones |
| :--- | :---: | :---: | :---: | :---: |
| **Sector NO** (Noroeste) | $[-2160, 0]$ | $[-2160, 0]$ | `Vector2(-1080, -1080)` | $2160 \times 2160\text{ px}$ |
| **Sector NE** (Noreste) | $[0, 2160]$ | $[-2160, 0]$ | `Vector2(1080, -1080)` | $2160 \times 2160\text{ px}$ |
| **Sector SO** (Suroeste) | $[-2160, 0]$ | $[0, 2160]$ | `Vector2(-1080, 1080)` | $2160 \times 2160\text{ px}$ |
| **Sector SE** (Sureste) | $[0, 2160]$ | $[0, 2160]$ | `Vector2(1080, 1080)` | $2160 \times 2160\text{ px}$ |

---

## 2. Delimitación Física y Límites Visuales

### 2.1. Valla Perimetral Infranqueable
En la escena raíz del escenario (`escenas/escenario.tscn`), se implementa una barrera estática fija:
* **Nodo:** `VallaPerimetral (StaticBody2D)`
* **Capa de Colisión:** Capa 1 (`Mundo_Alto` / Bloqueo Total).
* **Geometría de Muros:** 4 nodos `CollisionShape2D` (forma `RectangleShape2D` de $64\text{ px}$ de grosor):
  - **Muro Norte:** Posición `(0, -2160)`, tamaño `Vector2(4320, 64)`.
  - **Muro Sur:** Posición `(0, 2160)`, tamaño `Vector2(4320, 64)`.
  - **Muro Oeste:** Posición `(-2160, 0)`, tamaño `Vector2(64, 4320)`.
  - **Muro Este:** Posición `(2160, 0)`, tamaño `Vector2(64, 4320)`.
* **Inmutabilidad:** Esta barrera es permanente y nunca se altera al mutar los sectores interiores, asegurando que ni el jugador ni el monstruo puedan escapar de la arena.

### 2.2. Encuadre de Cámara (`Camera2D`)
Para la resolución nativa cuadrada $1:1$ ($1080 \times 1080\text{ px}$), el nodo `Camera2D` utiliza los límites nativos del motor:
```gdscript
limit_left = -2160
limit_top = -2160
limit_right = 2160
limit_bottom = 2160
position_smoothing_enabled = true
```
* La cámara sigue al personaje centrado en el viewport. Al aproximarse a los límites perimetrales, el paneo se detiene con suavidad, evitando mostrar el vacío exterior.

---

## 3. Matriz de Capas de Físicas del Entorno

| Capa | Nombre | Elementos del Escenario | Máscara Jugador | Máscara Monstruo |
| :---: | :--- | :--- | :---: | :---: |
| **1** | `Mundo_Alto` | Valla exterior, árboles frondosos, rocas grandes | **Activa** (Bloquea) | **Activa** (Bloquea) |
| **2** | `Obstaculos_Bajos` | Troncos caídos, tocones, piedras bajas | **Activa en Suelo** / **Inactiva en Salto/Dive** | **Activa Permanente** (Bloquea/Rodea) |

---

## 4. Corredores de Conectividad Intersectorial ($160\text{ px}$)

Alrededor de los ejes divisores $X = 0$ e $Y = 0$, se mantiene una **franja despejada obligatoria de al menos $160\text{ px}$ de ancho** ($80\text{ px}$ a cada lado del borde interior de cada cuadrante).

```text
                  │ 80px │ 80px │
                  │ Zona │ Zona │
                  │Libre │Libre │
      Sector NO   │ NO   │ NE   │   Sector NE
                  │      │      │
 ─────────────────┼──────┼──────┼─────────────────  Y = 0
                  │ 80px │ 80px │
      Sector SO   │ Zona │ Zona │   Sector SE
                  │Libre │Libre │
                  │ SO   │ SE   │
                  │      │      │
                         X = 0
```

* **Regla Estricta de Diseño:** Ninguna variante puede contener obstáculos sólidos dentro de estos $80\text{ px}$ limítrofes.
* **Propósito:** Garantizar que el tránsito entre cuadrantes sea siempre expedito y libre de estrangulamientos ciegos, sin importar la combinación procedural activa.

---

## 5. Arquitectura de Nodos y Estructura de Variantes

### 5.1. Árbol de la Escena Maestra (`escenas/escenario.tscn`)
```text
Escenario (Node2D) [scripts/escenario.gd]
├── SueloContinuo (Polygon2D continuo de 4320x4320 px, z_index: -10)
├── VallaPerimetral (StaticBody2D, Capa 1: Mundo_Alto)
│   ├── ColisionNorte / ColisionSur / ColisionOeste / ColisionEste
│   └── VisualValla (Node2D con Polygon2D perimetrales en z_index: 10)
├── Sectores (Node2D, y_sort_enabled = true)
│   ├── SectorNO (Marker2D en [-1080, -1080]) ──> Instancia de Variante activa
│   ├── SectorNE (Marker2D en [ 1080, -1080]) ──> Instancia de Variante activa
│   ├── SectorSO (Marker2D en [-1080,  1080]) ──> Instancia de Variante activa
│   └── SectorSE (Marker2D en [ 1080,  1080]) ──> Instancia de Variante activa
└── EfectoNieblaMutacion (CanvasLayer, layer 15) [scripts/efecto_niebla_mutacion.gd]
```

### 5.2. Estructura de Sub-Escena de Variante (`escenas/sectores/variantes/`)
Cada variante cubre un cuadrante de $2160 \times 2160\text{ px}$ con origen `(0, 0)` en su centro relativo:

```text
VarianteSector (Node2D, y_sort_enabled = true)
├── ObstaculosAltos (StaticBody2D - Capa 1: Mundo_Alto)
│   ├── Arboles (CollisionShape2D circulares en bases)
│   └── RocasGrandes
├── ObstaculosBajos (StaticBody2D - Capa 2: Obstaculos_Bajos)
│   └── TroncosCaidos (CollisionShape2D rectangulares)
└── PuntosDeNota (Node2D)
    ├── MarkerNota1 (Marker2D, grupo: "puntos_nota")
    ├── MarkerNota2 (Marker2D, grupo: "puntos_nota")
    └── MarkerNota3 (Marker2D, grupo: "puntos_nota")
```

### 5.3. Requisitos para Nuevas Variantes
Al crear una nueva variante en `escenas/sectores/variantes/`:
1. Asegurar que las dimensiones exteriores no superen $[-1080, 1080]$ en $X$ e $Y$.
2. Dejar $80\text{ px}$ libres de obstáculos sólidos en los bordes que toquen los ejes $X=0$ o $Y=0$.
3. Incluir entre **2 y 4 nodos `Marker2D`** pertenecientes al grupo `"puntos_nota"`.
4. Asignar los obstáculos a las capas correctas: Capa 1 para árboles y rocas altas; Capa 2 para troncos caídos bajos superables con salto.
