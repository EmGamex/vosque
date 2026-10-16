# Roadmap e Hitos de Producción

Este documento detalla el cronograma de desarrollo acotado a 4 semanas para alcanzar la meta de lanzamiento en Halloween (31 de Octubre).

---

## 1. Cronograma General (Gantt)

```mermaid
gantt
    title Calendario de Producción Halloween (4 Semanas)
    dateFormat  YYYY-MM-DD
    section Prototipo Base
    Movimiento Jugador & Input Teclado   :done, a1, 2026-10-04, 3d
    IA Monstruo & Spawner Notas          :active, a2, after a1, 4d
    section Pipeline Artístico
    Bases 3D en Blender                  :b1, 2026-10-11, 3d
    Entintado & Color en Inkscape        :b2, after b1, 4d
    section Integración & Web
    Importación a Godot & Luces 2D       :c1, 2026-10-18, 3d
    Exportación HTML5 & Test PC          :c2, after c1, 4d
    section Pulido & Lanzamiento
    Arte Promocional & Portada           :d1, 2026-10-25, 3d
    Publicación Newgrounds/itch.io       :d2, after d1, 3d
```

---

## 2. Entregables Clave por Semana

| Periodo | Objetivo Principal | Entregables Clave |
| :--- | :--- | :--- |
| **Semana 1** | Base funcional (Graybox) | Movimiento fluido, IA básica del monstruo con colisiones, sistema de spawn de notas y Game Over funcional en Godot. |
| **Semana 2** | Pipeline Artístico (Blender + Inkscape) | Modelado de volúmenes base en Blender, entintado vectorial en Inkscape, exportación de sprites y efectos de sonido. |
| **Semana 3** | Adaptación Web y Test PC | Optimización de exportación a HTML5, pruebas directas en navegadores de escritorio y balanceo de velocidad y dificultad. |
| **Semana 4** | Pulido, Promo y Lanzamiento | Arte promocional (portada tenebrosa), miniaturas, publicación en Newgrounds e itch.io, y videos cortos (devlogs). |
