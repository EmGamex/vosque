# Guía de Estilo y Lista de Assets

Este documento define la dirección artística, paleta de colores y el catálogo de recursos visuales requeridos para *Vosque*.

---

## 1. Dirección Artística

* **Tono Visual:** Terror arcade / Novela gráfica sombría.
* **Trazos:** Líneas negras gruesas y marcadas en los contornos, con rayado sutil para simular textura.
* **Paleta de Color:**
  - Fondos y bosque: Verdes musgo oscuros, tierras grisáceas y negros profundos.
  - Protagonista: Tonos claros/contrastantes para ser legible en penumbra.
  - Criatura: Silueta grotesca, ojos brillantes o extremidades desproporcionadas.
  - Notas coleccionables: Blanco amarillento envejecido con manchas de tinta o sangre.

---

## 2. Catálogo de Sprites (Checklist de Producción)

### 2.1. Entidades Principales
- [ ] **Jugador:** Sprite / Spritesheet de movimiento en 8 direcciones ($128 \times 128$ px).
- [ ] **Monstruo:** Sprite / Spritesheet de persecución y estado frenético ($128 \times 128$ px).
- [ ] **Nota Coleccionable:** Sprite con animación leve de destello o rotación ($64 \times 64$ px).

### 2.2. Entorno y Bosque
- [ ] **Árbol Tipo A:** Copa densa para obstruir visión y colisión ($256 \times 256$ px).
- [ ] **Árbol Tipo B:** Variante más delgada o seca ($256 \times 256$ px).
- [ ] **Rocas / Peñascos:** Obstáculos medianos para corte de trayectoria ($128 \times 128$ px).
- [ ] **Tronco Caído:** Obstáculo horizontal alargado.
- [ ] **Valla Perimetral:** Módulos de madera rota para marcar los bordes de la arena.
- [ ] **Suelo:** Tile / textura de tierra oscura y hojas marchitas.

### 2.3. Iluminación y Efectos Visuales
- [ ] **Textura de Linterna:** Gradiente radial en escala de grises para el `PointLight2D` ($512 \times 512$ px).
- [ ] **Flash de Nota:** 4 a 6 ilustraciones vectoriales de dibujos siniestros a pantalla completa.
- [ ] **Pantalla de Game Over:** Arte vectorial de jumpscare/derrota dramática con estática.
