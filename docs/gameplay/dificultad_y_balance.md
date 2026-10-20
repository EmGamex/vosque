# Dificultad y Balance

Este documento define las reglas de progresión cuantitativa, escalado de velocidad del monstruo y distribución espacial de las notas para mantener la tensión arcade en **Vosque**.

---

## 1. Progresión Cuantitativa por Notas Recogidas

El juego utiliza un escalado continuo de peligro por nota recolectada dentro de la misma sesión. Para evitar contradicciones matemáticas y mantener la jugabilidad justa, la velocidad del monstruo está acotada entre $500\text{ px/s}$ y un tope máximo estricto de $920\text{ px/s}$:

| Nota Recogida | Fase de Comportamiento | Velocidad Monstruo | Relación vs Jugador ($800\text{ px/s}$) | Dinámica de Juego |
| :---: | :--- | :---: | :---: | :--- |
| **0 (Inicio)** | *Acecho Silente* | $500\text{ px/s}$ | $62.5\%$ | Fase inicial de aclimatación; el jugador explora la oscuridad y ubica la primera baliza luminosa. |
| **Nota 1** | *Patrulla Lenta* | $540\text{ px/s}$ | $67.5\%$ | El jugador puede dejar atrás al enemigo caminando en línea recta. |
| **Nota 2** | *Patrulla Lenta* | $580\text{ px/s}$ | $72.5\%$ | El sonido de pasos y crujidos del monstruo se vuelve más persistente. |
| **Nota 3** | *Patrulla Lenta* | $620\text{ px/s}$ | $77.5\%$ | Comienza a cerrarse la brecha de distancia si el jugador se detiene a inspeccionar callejones sin salida. |
| **Nota 4** | *Persecución Media* | $680\text{ px/s}$ | $85.0\%$ | Los errores de navegación entre árboles comienzan a costar distancia valiosa. |
| **Nota 5** | *Persecución Media* | $730\text{ px/s}$ | $91.2\%$ | Exige giros cerrados y primer uso táctico de saltos sobre troncos bajos. |
| **Nota 6** | *Persecución Media* | $770\text{ px/s}$ | $96.2\%$ | El monstruo casi empareja el paso del jugador; el sprint se vuelve necesario para distanciarse. |
| **Nota 7** | *Persecución Media* | $800\text{ px/s}$ | $100.0\%$ | **Punto de inflexión:** El monstruo iguala exactamente la velocidad de caminata normal del jugador. |
| **Nota 8** | *Cacería Frenética* | $840\text{ px/s}$ | $105.0\%$ | Caminar ya no es suficiente; el jugador debe alternar sprint y saltos para evitar ser alcanzado. |
| **Nota 9** | *Cacería Frenética* | $880\text{ px/s}$ | $110.0\%$ | Persecución crítica; cualquier impacto fallido de plancha (*Dive*) o fatiga de estamina es letal. |
| **Nota 10+** | *Cacería Frenética (Tope)* | $920\text{ px/s}$ | $115.0\%$ | **Tope Máximo:** El jugador conserva una ventaja de $+80\text{ px/s}$ únicamente durante el Sprint ($1000\text{ px/s}$). |

---

## 2. Modelo Matemático y Límites

La función de velocidad implementa un incremento progresivo amortiguado con límite superior:

$$\text{Velocidad}(n) = \min\left(920.0, \; 500.0 + 42.0 \times n\right)$$

* **Tope de Seguridad ($920\text{ px/s}$):** Garantiza que el juego nunca se vuelva imposible matemáticamente. Puesto que el Sprint alcanza $1000\text{ px/s}$, el jugador siempre tiene un margen de escape si administra correctamente su barra de estamina y esquiva entre árboles y troncos bajos.
* **Aceleración Física:** El monstruo conserva una aceleración constante de $3500\text{ px/s}^2$ en todo momento, otorgándole un giro ligeramente más abierto en curvas que el del jugador ($5000\text{ px/s}^2$), incentivando los desvíos bruscos en pasillos de árboles.

---

## 3. Dinámica durante la Mutación de Sectores

Al recolectar una nota, el escenario entra en el ciclo de mutación espacial bajo niebla:
1. **Comportamiento del Monstruo en Niebla:** Durante los $0.4\text{ s}$ de oscuridad total (`pausa_oscuridad`), el monstruo continúa activo, pero su velocidad se modula temporalmente al $50\%$ para evitar muertes a ciegas injustas mientras el círculo de visión del jugador está cerrado.
2. **Reubicación de Seguridad:** Si tras la mutación el monstruo queda solapado con un árbol o roca de la variante recién cargada, se traslada de inmediato al `Marker2D` libre más cercano.
3. **Criterio de Spawn de la Nueva Nota:**
   - La nueva nota se genera en uno de los puntos candidatos de los **3 sectores lejanos mutados**.
   - Se excluye estrictamente el cuadrante donde se encuentra el jugador.
   - Se impone una distancia mínima de seguridad:
     $$\text{distancia}(\text{nota}, \text{jugador}) \ge 600\text{ px} \quad \text{y} \quad \text{distancia}(\text{nota}, \text{monstruo}) \ge 800\text{ px}$$
