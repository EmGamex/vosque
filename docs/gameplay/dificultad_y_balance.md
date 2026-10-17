# Dificultad y Balance

Este documento define las reglas de progresión, escalado de velocidad y distribución espacial de las notas para mantener la tensión arcade.

---

## 1. Progresión por Tramos de Notas

El juego no utiliza un sistema de niveles, sino un escalado continuo de peligro dentro de la misma sesión:

| Rango de Notas | Fase de Comportamiento | Relación de Velocidad | Dinámica de Juego |
| :--- | :--- | :--- | :--- |
| **Notas 1 a 3** | *Patrulla Lenta* | Monstruo más lento que el jugador (~$60\% - 75\%$) | Fase de aprendizaje; el jugador aprende a maniobrar entre árboles y explorar los límites del mapa. |
| **Notas 4 a 7** | *Persecución Media* | Monstruo iguala la velocidad del jugador (~$95\% - 100\%$) | Exige giros cerrados, rutas óptimas y uso activo de obstáculos para sacarle ventaja. |
| **Notas 8+** | *Cacería Frenética* | Monstruo ligeramente más rápido en línea recta (~$105\% - 115\%$) | Obliga a zigzaguear constantemente entre obstáculos para romper la línea de visión y evitar ser alcanzado. |

---

## 2. Escalado de Velocidad del Monstruo

Al recolectar cada nota, la velocidad base de la criatura se incrementa siguiendo un multiplicador acumulativo:

$$\text{Velocidad}(n) = \text{Velocidad Base} \times (1 + \text{Tasa Incremento})^{n}$$

* **Tasa de incremento sugerida:** Entre $+5\%$ y $+10\%$ por nota recogida.
* **Tope de velocidad:** Limitado a un valor máximo maniobrable para que el juego siga siendo superable mediante habilidad y esquiva entre árboles.

---

## 3. Criterio de Reubicación de Notas y Mutación Espacial

Para evitar situaciones injustas o notas que aparezcan encima del jugador o del monstruo, y para sacar provecho de la arquitectura de 4 sectores:
1. Cada variante de sector contiene sus propios nodos candidatos de spawn (`Marker2D`).
2. Al recoger una nota, se mutan las variantes de los **3 sectores lejanos** (donde no se encuentra el jugador).
3. La nueva nota se genera aleatoriamente en uno de los puntos candidatos pertenecientes a cualquiera de los **3 sectores recién mutados**, garantizando:
   - Que nunca aparezca en el sector actual del jugador ni a una distancia menor a $R_{\min}$.
   - Que el jugador se vea obligado a desplazarse activamente hacia zonas oscuras cuya distribución y pasillos acaban de cambiar.

