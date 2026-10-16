# Audio y Feedback Sensorial

Este documento describe el paisaje sonoro, los efectos de audio (SFX) y los recursos de respuesta táctil y visual para generar terror y tensión en *Vosque*.

---

## 1. Diseño de Audio

El audio es un elemento de jugabilidad fundamental, ya que sirve como radar sonoro en medio de la oscuridad.

### Catálogo de Efectos de Sonido (SFX)
* **Pasos del Jugador:** Pasos sordos y crujidos de hojas secas en el bosque.
* **Proximidad del Monstruo:** Sonido gutural bajo o zumbido de estática radial que aumenta de volumen a medida que la criatura se acerca a la posición del jugador.
* **Recolección de Nota:** Golpe de cuerda disonante, rasgado de papel o acorde tenso que resalta el logro pero aumenta la alarma.
* **Jumpscare / Atrapado:** Golpe orquestal repentino o chillido distorsionado sincronizado con el contacto del monstruo.

---

## 2. Feedback Sensorial y Visual

* **Dentro del Haz de Luz:** Cuando el monstruo penetra el radio del `PointLight2D` del jugador:
  - Se activa una ligera vibración de cámara (*Camera Shake*).
  - La intensidad de la luz puede parpadear sutilmente.
* **Ambiente de Fondo:** Viento frío aullando entre las ramas y silencio ominoso para acentuar los ruidos repentinos.
