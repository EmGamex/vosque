@tool
class_name MenuInicio
extends Control

## Menú de inicio interactivo con sistema de cinemática modular y linterna en primera persona.
## Dispone de dos lienzos espaciales continuos en el espacio 2D:
## - Zona superior (Cielo/Presentación): Logotipo y aviso "Presiona ENTER para comenzar".
## - Zona inferior (Bosque/Menú): Tres árboles iluminados por linterna (Opciones, Jugar, Créditos).
## Orquestador/Fachada modular que delega en controladores especializados bajo res://scripts/menu_inicio/.

signal jugar_solicitado
signal opciones_solicitado
signal creditos_solicitado

# Constantes y Enums re-exportados para compatibilidad
const EstadoMenu = MenuConstantes.EstadoMenu
const Opcion = MenuConstantes.Opcion
const ORDEN_OPCIONES = MenuConstantes.ORDEN_OPCIONES
const COLOR_SELECCIONADO = MenuConstantes.COLOR_SELECCIONADO
const COLOR_NO_SELECCIONADO = MenuConstantes.COLOR_NO_SELECCIONADO
const DURACION_TRANSICION = MenuConstantes.DURACION_TRANSICION
const TEXTURA_OPCIONES = MenuConstantes.TEXTURA_OPCIONES
const TEXTURA_JUGAR = MenuConstantes.TEXTURA_JUGAR
const TEXTURA_CREDITOS = MenuConstantes.TEXTURA_CREDITOS
const TEXTURAS_OPCIONES = MenuConstantes.TEXTURAS_OPCIONES

# ==========================================
# CONFIGURACIÓN CINEMÁTICA Y PARTÍCULAS (INSPECTOR)
# ==========================================
@export_group("Cinemática de Inicio")
@export var habilitar_presentacion: bool:
	get: return cinematica.habilitar_presentacion if cinematica != null else true
	set(v): if cinematica != null: cinematica.habilitar_presentacion = v

@export_range(1.5, 10.0, 0.5) var multiplicador_velocidad_skip: float:
	get: return cinematica.multiplicador_velocidad_skip if cinematica != null else 4.0
	set(v): if cinematica != null: cinematica.multiplicador_velocidad_skip = v

@export_group("Partículas y Ambiente")
@export_subgroup("Estrellas")
@export var habilitar_estrellas: bool:
	get: return particulas.habilitar_estrellas if particulas != null else true
	set(v):
		if particulas != null:
			particulas.habilitar_estrellas = v
			particulas.aplicar_configuracion_estrellas()

@export_range(5, 200, 1) var estrellas_cantidad: int:
	get: return particulas.estrellas_cantidad if particulas != null else 55
	set(v):
		if particulas != null:
			particulas.estrellas_cantidad = v
			particulas.aplicar_configuracion_estrellas()

@export_range(0.5, 15.0, 0.1) var estrellas_lifetime: float:
	get: return particulas.estrellas_lifetime if particulas != null else 4.5
	set(v):
		if particulas != null:
			particulas.estrellas_lifetime = v
			particulas.aplicar_configuracion_estrellas()

@export_range(0.1, 2.0, 0.05) var estrellas_escala_min: float:
	get: return particulas.estrellas_escala_min if particulas != null else 0.35
	set(v):
		if particulas != null:
			particulas.estrellas_escala_min = v
			particulas.aplicar_configuracion_estrellas()

@export_range(0.2, 3.0, 0.05) var estrellas_escala_max: float:
	get: return particulas.estrellas_escala_max if particulas != null else 0.95
	set(v):
		if particulas != null:
			particulas.estrellas_escala_max = v
			particulas.aplicar_configuracion_estrellas()

@export var estrellas_color: Color:
	get: return particulas.estrellas_color if particulas != null else Color.WHITE
	set(v):
		if particulas != null:
			particulas.estrellas_color = v
			particulas.aplicar_configuracion_estrellas()

@export_range(0.0, 0.5, 0.01) var estrellas_factor_parallax: float:
	get: return particulas.estrellas_factor_parallax if particulas != null else 0.08
	set(v): if particulas != null: particulas.estrellas_factor_parallax = v

@export_range(0.0, 0.5, 0.01) var estrellas_factor_rotacion: float:
	get: return particulas.estrellas_factor_rotacion if particulas != null else 0.06
	set(v): if particulas != null: particulas.estrellas_factor_rotacion = v

@export_subgroup("Nubes y Bruma")
@export var habilitar_nubes: bool:
	get: return particulas.habilitar_nubes if particulas != null else true
	set(v):
		if particulas != null:
			particulas.habilitar_nubes = v
			particulas.aplicar_configuracion_nubes()

@export_range(1, 30, 1) var nubes_cantidad: int:
	get: return particulas.nubes_cantidad if particulas != null else 10
	set(v):
		if particulas != null:
			particulas.nubes_cantidad = v
			particulas.aplicar_configuracion_nubes()

@export_range(0.0, 100.0, 1.0) var nubes_velocidad_x: float:
	get: return particulas.nubes_velocidad_x if particulas != null else 18.0
	set(v):
		if particulas != null:
			particulas.nubes_velocidad_x = v
			particulas.aplicar_configuracion_nubes()

@export_range(3.0, 40.0, 0.5) var nubes_lifetime: float:
	get: return particulas.nubes_lifetime if particulas != null else 16.0
	set(v):
		if particulas != null:
			particulas.nubes_lifetime = v
			particulas.aplicar_configuracion_nubes()

@export_range(0.5, 6.0, 0.1) var nubes_escala_min: float:
	get: return particulas.nubes_escala_min if particulas != null else 2.0
	set(v):
		if particulas != null:
			particulas.nubes_escala_min = v
			particulas.aplicar_configuracion_nubes()

@export_range(1.0, 8.0, 0.1) var nubes_escala_max: float:
	get: return particulas.nubes_escala_max if particulas != null else 4.2
	set(v):
		if particulas != null:
			particulas.nubes_escala_max = v
			particulas.aplicar_configuracion_nubes()

@export var nubes_color: Color:
	get: return particulas.nubes_color if particulas != null else Color(0.75, 0.82, 0.95, 0.16)
	set(v):
		if particulas != null:
			particulas.nubes_color = v
			particulas.aplicar_configuracion_nubes()

@export_range(0.0, 0.5, 0.01) var nubes_factor_parallax: float:
	get: return particulas.nubes_factor_parallax if particulas != null else 0.16
	set(v): if particulas != null: particulas.nubes_factor_parallax = v

@export_range(0.0, 0.5, 0.01) var nubes_factor_rotacion: float:
	get: return particulas.nubes_factor_rotacion if particulas != null else 0.12
	set(v): if particulas != null: particulas.nubes_factor_rotacion = v

# Controladores modulares (accesibles directamente)
var cinematica: MenuCinematica = MenuCinematica.new()
var particulas: MenuParticulas = MenuParticulas.new()
var parallax: MenuParallax = MenuParallax.new()
var seleccion: MenuSeleccion = MenuSeleccion.new()

# Propiedades públicas para consulta limpia y tests
var opcion_actual: Opcion:
	get: return seleccion.opcion_actual if seleccion != null else Opcion.JUGAR
	set(v): if seleccion != null: seleccion.opcion_actual = v

var bloqueado: bool:
	get: return seleccion.bloqueado if seleccion != null else false
	set(v): if seleccion != null: seleccion.bloqueado = v

var estado: EstadoMenu:
	get: return cinematica.estado if cinematica != null else EstadoMenu.PRESENTACION
	set(v): if cinematica != null: cinematica.estado = v

# Nodos
@onready var _camara: Camera2D = $CamaraMenu
@onready var _animador: AnimationPlayer = $AnimadorCinematica
@onready var _presentacion: Control = $Presentacion
@onready var _fondo_presentacion: Sprite2D = $Fondos/FondoPresentacion
@onready var _fondos: Node2D = $Fondos
@onready var _fondo_degradado: Sprite2D = $Fondos/FondoDegradado
@onready var _montana_2: Sprite2D = $Fondos/Montaña2
@onready var _montana_1: Sprite2D = $Fondos/Montaña1
@onready var _arboles_tercera: Sprite2D = $Fondos/ArbolesTerceraDivision
@onready var _arboles_segunda: Sprite2D = $Fondos/ArbolesSegundaDivision
@onready var _arboles_nodo: Node2D = $Arboles
@onready var _textos_nodo: Control = $Textos
@onready var _arbol_visual: Sprite2D = $Arboles/ArbolVisual
@onready var _particulas_estrellas: CPUParticles2D = $Fondos/ParticulasEstrellas
@onready var _particulas_nubes: CPUParticles2D = $Fondos/ParticulasNubes
@onready var _texto_opciones: Label = $Textos/TextoOpciones
@onready var _texto_jugar: Label = $Textos/TextoJugar
@onready var _texto_creditos: Label = $Textos/TextoCreditos


func _ready() -> void:
	if _textos_nodo != null:
		_textos_nodo.z_index = 10

	cinematica.inicializar_nodos(_camara, _animador, _presentacion, _fondo_presentacion, _textos_nodo)
	particulas.inicializar(self, _particulas_estrellas, _particulas_nubes)
	parallax.inicializar_nodos(_fondos, _fondo_degradado, _montana_2, _montana_1, _arboles_tercera, _arboles_segunda, _arboles_nodo, _textos_nodo)
	parallax.capturar_posiciones_iniciales(particulas.obtener_particulas_estrellas(), particulas.obtener_particulas_nubes())

	seleccion.inicializar_nodos(self, _arbol_visual, _texto_opciones, _texto_jugar, _texto_creditos)
	_conectar_senales_submodulos()
	_conectar_animador()

	iniciar_presentacion()
	_actualizar_seleccion(false)


func _conectar_senales_submodulos() -> void:
	if not seleccion.jugar_solicitado.is_connected(jugar_solicitado.emit):
		seleccion.jugar_solicitado.connect(jugar_solicitado.emit)
	if not seleccion.opciones_solicitado.is_connected(opciones_solicitado.emit):
		seleccion.opciones_solicitado.connect(opciones_solicitado.emit)
	if not seleccion.creditos_solicitado.is_connected(creditos_solicitado.emit):
		seleccion.creditos_solicitado.connect(creditos_solicitado.emit)
	if not seleccion.offset_rotacion_cambiado.is_connected(_on_offset_rotacion_cambiado):
		seleccion.offset_rotacion_cambiado.connect(_on_offset_rotacion_cambiado)


func _conectar_animador() -> void:
	if _animador != null and not _animador.animation_finished.is_connected(_on_animacion_terminada):
		_animador.animation_finished.connect(_on_animacion_terminada)


func _on_offset_rotacion_cambiado(nuevo_offset: Vector2, nueva_rotacion: float, animar: bool) -> void:
	if not animar and parallax != null:
		parallax.offset_base = nuevo_offset
		parallax.rotacion_base = nueva_rotacion


func _animar_offset_rotacion(tween: Tween, target_pos: Vector2, target_rot: float) -> void:
	if parallax != null:
		tween.tween_property(parallax, "offset_base", target_pos, DURACION_TRANSICION)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		tween.tween_property(parallax, "rotacion_base", target_rot, DURACION_TRANSICION)\
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func iniciar_presentacion() -> void:
	seleccion.opcion_actual = Opcion.JUGAR
	seleccion.bloqueado = false
	cinematica.iniciar_presentacion(Engine.is_editor_hint(), is_in_group("modo_test"))


func iniciar_descenso() -> void:
	cinematica.iniciar_descenso(_on_animacion_terminada)


func regresar_a_presentacion() -> void:
	if estado != EstadoMenu.MENU_ACTIVO or bloqueado:
		return
	seleccion.bloqueado = true
	seleccion.opcion_actual = Opcion.JUGAR
	_actualizar_seleccion(true)
	cinematica.regresar_a_presentacion(_on_animacion_terminada)


func skipear_cinematica() -> void:
	cinematica.skipear_cinematica()


func _on_animacion_terminada(nombre: StringName) -> void:
	var volvio_a_presentacion: bool = cinematica.procesar_animacion_terminada(nombre)
	if nombre == &"bajar_al_bosque":
		seleccion.bloqueado = false
		if volvio_a_presentacion:
			seleccion.opcion_actual = Opcion.JUGAR
			_actualizar_seleccion(false)
		else:
			_actualizar_seleccion(false)


func enfocar() -> void:
	iniciar_presentacion()
	_actualizar_seleccion(false)


func _navegar(direccion: int) -> void:
	seleccion.navegar(direccion)


func _actualizar_seleccion(animar: bool) -> void:
	seleccion.actualizar_seleccion(animar)


func _confirmar_opcion() -> void:
	seleccion.confirmar_opcion()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not is_in_group("modo_test"):
		return
	parallax.procesar_balanceo(
		delta,
		particulas.obtener_particulas_estrellas(),
		particulas.obtener_particulas_nubes(),
		estrellas_factor_parallax,
		estrellas_factor_rotacion,
		nubes_factor_parallax,
		nubes_factor_rotacion
	)


func _unhandled_input(evento: InputEvent) -> void:
	if Engine.is_editor_hint():
		return

	match estado:
		EstadoMenu.PRESENTACION:
			if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("personaje-salto"):
				iniciar_descenso()
				get_viewport().set_input_as_handled()

		EstadoMenu.CINEMATICA_BAJANDO, EstadoMenu.CINEMATICA_SUBIENDO:
			if evento.is_action_pressed("ui_accept") or evento.is_action_pressed("ui_cancel") or evento.is_action_pressed("personaje-salto"):
				skipear_cinematica()
				get_viewport().set_input_as_handled()

		EstadoMenu.MENU_ACTIVO:
			if bloqueado:
				return

			if evento.is_action_pressed("ui_cancel"):
				regresar_a_presentacion()
				get_viewport().set_input_as_handled()
			elif evento.is_action_pressed("personaje-izquierda") or evento.is_action_pressed("ui_left"):
				_navegar(-1)
				get_viewport().set_input_as_handled()
			elif evento.is_action_pressed("personaje-derecha") or evento.is_action_pressed("ui_right"):
				_navegar(1)
				get_viewport().set_input_as_handled()
			elif evento.is_action_pressed("ui_accept") or evento.is_action_pressed("personaje-salto"):
				_confirmar_opcion()
				get_viewport().set_input_as_handled()
