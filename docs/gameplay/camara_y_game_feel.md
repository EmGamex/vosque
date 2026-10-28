# Cámara y Game Feel

Este documento especifica el comportamiento dinámico de la cámara, el sistema de sacudidas de pantalla (*Camera Shake*) basado en trauma y los recursos visuales de post-procesamiento en **Vosque**.

---

## 1. Configuración de Cámara (`Camera2D`)

La cámara principal está centrada en el personaje para ofrecer una vista cenital equilibrada:
* **Resolución de Viewport:** Relación $1:1$ ($1080 \times 1080\text{ px}$).
* **Suavizado de Seguimiento:**
  ```gdscript
  position_smoothing_enabled = true
  position_smoothing_speed = 8.0 # Respuesta rápida sin retraso molesto
  ```
* **Límites de Mundo (Clamping Nativo):**
  ```gdscript
  limit_left = -2160
  limit_top = -2160
  limit_right = 2160
  limit_bottom = 2160
  ```
  Esto asegura que la cámara nunca muestre el vacío fuera de la valla perimetral del bosque.

---

## 2. Sistema de Sacudida Basado en Trauma (*Trauma-based Shake*)

Para lograr sacudidas viscerales pero no molestas, se utiliza el modelo de **Trauma Cuadrático** (popularizado por Squirrel Eiserloh):

$$\text{Desplazamiento} = \text{Trauma}^2 \times \text{AmplitudMáxima} \times \text{Ruido}(t)$$

### 2.1. Propiedades del Sistema
* **`trauma` ($0.0 \dots 1.0$):** Nivel de estrés acumulado en la cámara.
* **Tasa de Decaimiento:** El trauma se disipa linealmente a $-1.4\text{ pts/s}$ en cada frame:
  $$\text{trauma} = \max(0.0, \; \text{trauma} - \text{decay\_rate} \times \Delta t)$$
* **Amplitud Máxima:** Desplazamiento máximo de $18\text{ px}$ y rotación máxima de $3.0^\circ$.

### 2.2. Fuentes de Trauma en Partida

| Evento | Incremento de Trauma ($\Delta \text{Trauma}$) | Justificación de Game Feel |
| :--- | :---: | :--- |
| **Paso de Caminata Estándar** | $0.0$ | Cero sacudida para mantener la legibilidad de la navegación. |
| **Impacto de Salto Libre en Tierra** | $+0.05$ | Micro-vibración sutil que acentúa el peso del explorador. |
| **Impacto de Plancha (*Dive*)** | $+0.35$ | Golpe contundente que enfatiza el impacto contra la hojarasca y la vulnerabilidad. |
| **Monstruo en Haz de Luz (< 300 px)** | $+0.12\text{ / s}$ | Temblor de pánico continuo mientras la criatura se abalanza en línea de visión directa. |
| **Contacto Mortal (Jumpscare)** | $+1.00$ | Sacudida máxima violenta instantánea coordinada con el flash y el grito sonoro. |

---

## 3. Post-Procesamiento e Iluminación Atmosférica

> 💡 **Especificación completa:** Ver [Sistema de Iluminación](sistema_de_iluminacion.md) para el análisis cuantitativo de WebGL 2.0, cálculo matemático del cono y modulación por recolección de notas.

### 3.1. Iluminación Ambiental con `CanvasModulate`
* Color base: `Color(0.08, 0.10, 0.15, 1.0)`.
* Genera una penumbra azul petróleo que evita la oscuridad absoluta, permitiendo discernir las siluetas de los troncos a media distancia sin linterna. Conforme se recogen notas, se oscurece gradualmente intensificando la tensión.

### 3.2. Linterna y Alto Contraste
* La linterna frontal (`PointLight2D`) recorta la oscuridad con una textura cónica de alta penetración ($700\text{ px}$ de alcance, $60^\circ$ de apertura).
* Actúa como el elemento de contraste principal que revela detalles, texturas y los ojos retro-reflectantes del enemigo (`LIGHT_MODE_UNSHADED`). Al penetrar la bestia en el haz, desencadena un titileo estocástico electromagnético ($\pm 10\%$) e incrementa el trauma de estrés de la cámara ($+0.12\text{ / s}$).
