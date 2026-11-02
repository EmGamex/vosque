class_name MenuConstantes
extends RefCounted

## Constantes, enums y recursos visuales compartidos para el menú de inicio.

enum EstadoMenu { PRESENTACION, CINEMATICA_BAJANDO, MENU_ACTIVO, CINEMATICA_SUBIENDO }
enum Opcion { OPCIONES, JUGAR, CREDITOS }

const ORDEN_OPCIONES: Array[Opcion] = [Opcion.OPCIONES, Opcion.JUGAR, Opcion.CREDITOS]

const COLOR_SELECCIONADO: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_NO_SELECCIONADO: Color = Color(1.0, 1.0, 1.0, 0.16)
const DURACION_TRANSICION: float = 0.35

const TEXTURA_OPCIONES: Texture2D = preload("res://graficos/menu principal/variacion izquierda inicio.png")
const TEXTURA_JUGAR: Texture2D = preload("res://graficos/menu principal/manu seleccion inicio.png")
const TEXTURA_CREDITOS: Texture2D = preload("res://graficos/menu principal/variacion derecha inicio.png")

const TEXTURAS_OPCIONES: Dictionary = {
	Opcion.OPCIONES: TEXTURA_OPCIONES,
	Opcion.JUGAR: TEXTURA_JUGAR,
	Opcion.CREDITOS: TEXTURA_CREDITOS,
}

# Factores de desplazamiento de parallax para cada capa de fondo
const FACTOR_PARALLAX_DEGRADADO: float = 0.08
const FACTOR_PARALLAX_MONTANA_2: float = 0.22
const FACTOR_PARALLAX_MONTANA_1: float = 0.45
const FACTOR_PARALLAX_ARBOLES_3: float = 0.60
const FACTOR_PARALLAX_ARBOLES_2: float = 0.78

# Factores de rotación de parallax
const FACTOR_ROTACION_DEGRADADO: float = 0.06
const FACTOR_ROTACION_MONTANA_2: float = 0.18
const FACTOR_ROTACION_MONTANA_1: float = 0.35
const FACTOR_ROTACION_ARBOLES_3: float = 0.50
const FACTOR_ROTACION_ARBOLES_2: float = 0.65
