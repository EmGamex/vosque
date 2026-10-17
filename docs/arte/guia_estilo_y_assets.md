# Guía de Estilo y Lista de Assets

Este documento define la dirección artística, paleta de colores y el catálogo de recursos visuales requeridos para *Vosque*.

---

## 1. Dirección Artística
 
* **Tono Visual:** Terror arcade / Novela gráfica sombría con alto contraste.
* **Trazos:** Líneas negras gruesas y marcadas en los contornos, con rayado sutil para simular textura.
* **Modelo de Iluminación:** **Penumbra Contrastada (Noche Americana)**. En lugar de oscuridad ciega, se mantiene una base visible de tonos fríos para permitir lectura espacial rápida a $800 - 1000\text{ px/s}$.
* **Paleta de Color:**
  - Fondos y bosque: Azul petróleo oscuro (`#141824`), verdes musgo oscuros, tierras grisáceas y negros profundos.
  - Protagonista: Tonos claros/contrastantes para ser legible en penumbra.
  - Criatura: Silueta grotesca oscura con ojos retro-reflectantes amarillo/rojo brillante.
  - Notas coleccionables: Papel blanco envejecido con halo luminoso propio y manchas de tinta/sangre.

---

## 2. Catálogo de Sprites (Checklist de Producción)

### 2.1. Entidades Principales
- [ ] **Jugador:** Spritesheet de movimiento en 8 direcciones, pose de elevación de salto, pose horizontal de plancha (*dive*) y frame de recuperación en el suelo ($128 \times 128$ px).
- [ ] **Monstruo:** Sprite / Spritesheet de persecución y estado frenético con ojos auto-iluminados ($128 \times 128$ px).
- [ ] **Nota Coleccionable:** Sprite con textura de papel viejo ($64 \times 64$ px) y textura de halo luminoso radial.

### 2.2. Entorno y Bosque
- [ ] **Árbol Tipo A:** Copa densa para obstruir visión y colisión ($256 \times 256$ px).
- [ ] **Árbol Tipo B:** Variante más delgada o seca ($256 \times 256$ px).
- [ ] **Rocas / Peñascos:** Obstáculos medianos para corte de trayectoria ($128 \times 128$ px).
- [ ] **Tronco Caído:** Obstáculo horizontal alargado (obstáculo bajo para salto *Dive*).
- [ ] **Valla Perimetral:** Módulos de madera rota para marcar los bordes de la arena.
- [ ] **Suelo:** Tile / textura de tierra oscura y hojas marchitas.

### 2.3. Iluminación y Efectos Visuales
- [ ] **Textura de Linterna:** Gradiente radial en escala de grises para el `PointLight2D` frontal ($512 \times 512$ px) y halo 360° corporal ($256 \times 256$ px).
- [ ] **Halo de Nota:** Gradiente circular suave para la luz propia de la nota coleccionable ($256 \times 256$ px).
- [ ] **Flash de Nota:** 4 a 6 ilustraciones vectoriales de dibujos siniestros a pantalla completa.
- [ ] **Pantalla de Game Over:** Arte vectorial de jumpscare/derrota dramática con estática.
