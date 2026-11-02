@tool
class_name EfectoNieblaMutacion
extends CanvasLayer

## Fachada y coordinador visual del efecto de niebla geométrica durante las mutaciones de escenario.
## Gestiona el nodo CanvasLayer y delega en NieblaMaterialController, NieblaFocoController y NieblaTransicionController.

signal ceguera_alcanzada
signal niebla_disipada
signal oscuridad_iniciada
signal oscuridad_terminada

const Fase = NieblaTransicionController.Fase

@export var config: ConfiguracionNiebla:
	set(val):
		if config != null and config.changed.is_connected(_on_config_changed):
			config.changed.disconnect(_on_config_changed)
		config = val
		if config != null:
			if not config.changed.is_connected(_on_config_changed):
				config.changed.connect(_on_config_changed)
		_actualizar_parametros_shader()

@export_group("Previsualización en Viewport (Editor)")
@export var previsualizar_en_editor: bool = false:
	set(val):
		previsualizar_en_editor = val
		_actualizar_estado_previsualizacion()

@export_range(0.0, 1.0, 0.05) var previsualizar_densidad: float = 1.0:
	set(val):
		previsualizar_densidad = val
		_actualizar_estado_previsualizacion()

@export_group("Depuración y Anulación")
@export var desactivado: bool = false:
	set(val):
		if desactivado == val:
			return
		desactivado = val
		if desactivado:
			_abortar_y_limpiar()
		else:
			visible = false
			set_process(false)
			if material_ctrl != null:
				material_ctrl.actualizar_radio_interno(radio_despejado)
				material_ctrl.actualizar_densidad(0.0)

@export_group("Objetivo de Enfoque")
@export var objetivo_jugador: Node2D

@onready var color_rect: ColorRect = get_node_or_null("ColorRect") as ColorRect

# Sub-controladores modulares
var material_ctrl: NieblaMaterialController = NieblaMaterialController.new()
var foco_ctrl: NieblaFocoController = NieblaFocoController.new()
var transicion_ctrl: NieblaTransicionController = NieblaTransicionController.new()

# Acceso directo a propiedades clave delegadas
var fase_actual: NieblaTransicionController.Fase:
	get: return transicion_ctrl.fase_actual
	set(v): transicion_ctrl.fase_actual = v

var radio_despejado: float:
	get: return _cfg().radio_despejado
	set(v): _cfg().radio_despejado = v

var radio_cerrado: float:
	get: return _cfg().radio_cerrado
	set(v): _cfg().radio_cerrado = v

var duracion_cierre: float:
	get: return _cfg().duracion_cierre
	set(v): _cfg().duracion_cierre = v

var pausa_oscuridad: float:
	get: return _cfg().pausa_oscuridad
	set(v): _cfg().pausa_oscuridad = v

var duracion_apertura: float:
	get: return _cfg().duracion_apertura
	set(v): _cfg().duracion_apertura = v

var centro_pantalla: Vector2:
	get: return _cfg().centro_pantalla
	set(v): _cfg().centro_pantalla = v


func _cfg() -> ConfiguracionNiebla:
	if config == null:
		config = ConfiguracionNiebla.new()
		if not config.changed.is_connected(_on_config_changed):
			config.changed.connect(_on_config_changed)
	return config


func _on_config_changed() -> void:
	_actualizar_parametros_shader()


func _init() -> void:
	visible = false


func _ready() -> void:
	layer = 15
	_cfg()
	if color_rect == null:
		color_rect = get_node_or_null("ColorRect") as ColorRect

	material_ctrl.inicializar_material(color_rect, Engine.is_editor_hint(), previsualizar_en_editor, _cfg())

	if Engine.is_editor_hint():
		if not is_in_group("modo_test"):
			_actualizar_estado_previsualizacion()
			return

	visible = false
	set_process(false)
	_resolver_referencia_jugador()


func _process(delta: float) -> void:
	transicion_ctrl.actualizar_proceso(delta, material_ctrl)
	_actualizar_posicion_foco()


func _actualizar_estado_previsualizacion() -> void:
	if not Engine.is_editor_hint():
		return

	if material_ctrl.material_shader == null:
		if color_rect == null:
			color_rect = get_node_or_null("ColorRect") as ColorRect
		material_ctrl.inicializar_material(color_rect, true, previsualizar_en_editor, _cfg())

	if previsualizar_en_editor:
		visible = true
		set_process(true)
		material_ctrl.aplicar_previsualizacion(true, previsualizar_densidad, _cfg())
		_actualizar_posicion_foco()
	else:
		visible = false
		set_process(false)
		material_ctrl.aplicar_previsualizacion(false, 0.0, _cfg())


func _resolver_referencia_jugador() -> void:
	objetivo_jugador = foco_ctrl.resolver_jugador(self, objetivo_jugador)


func _actualizar_posicion_foco() -> void:
	if not is_inside_tree():
		return

	if objetivo_jugador != null and not is_instance_valid(objetivo_jugador):
		objetivo_jugador = null

	if not Engine.is_editor_hint() and objetivo_jugador == null:
		_resolver_referencia_jugador()

	var res := foco_ctrl.calcular_foco_y_aspecto(self, objetivo_jugador, centro_pantalla, Engine.is_editor_hint())
	if res.get("valido", false):
		material_ctrl.actualizar_foco(res.get("centro", centro_pantalla), res.get("aspecto", 1.0))


func _actualizar_parametros_shader() -> void:
	material_ctrl.actualizar_parametros_estaticos(_cfg())
	_actualizar_posicion_foco()


func _abortar_y_limpiar() -> void:
	visible = false
	set_process(false)
	transicion_ctrl.abortar_y_limpiar(
		material_ctrl,
		_cfg(),
		Callable(self, "_emit_ceguera"),
		Callable(self, "_emit_oscuridad_terminada"),
		Callable(self, "_emit_niebla_disipada")
	)


## Cubre la pantalla proyectando las cápsulas geométricas de niebla.
func cubrir(duracion: float = -1.0) -> void:
	transicion_ctrl.cubrir(
		self,
		duracion,
		_cfg(),
		material_ctrl,
		desactivado,
		Callable(self, "_emit_ceguera")
	)


## Despeja la pantalla abriendo el halo y desvaneciendo las cápsulas.
func despejar(duracion: float = -1.0) -> void:
	transicion_ctrl.despejar(
		self,
		duracion,
		_cfg(),
		material_ctrl,
		desactivado,
		Callable(self, "_emit_niebla_disipada")
	)


func _emit_ceguera() -> void:
	ceguera_alcanzada.emit()


func _emit_niebla_disipada() -> void:
	niebla_disipada.emit()


func _emit_oscuridad_terminada() -> void:
	oscuridad_terminada.emit()


## Ciclo completo de mutación con protección asíncrona mediante tokens.
func ejecutar_transicion(
	accion_en_ceguera: Callable = Callable(),
	t_cierre: float = -1.0,
	t_apertura: float = -1.0,
	t_pausa: float = -1.0
) -> void:
	if desactivado:
		transicion_ctrl.animando = false
		transicion_ctrl.fase_actual = NieblaTransicionController.Fase.DESPEJADO
		visible = false
		set_process(false)
		if material_ctrl != null:
			material_ctrl.actualizar_radio_interno(radio_despejado)
			material_ctrl.actualizar_densidad(0.0)

		if accion_en_ceguera.is_valid():
			accion_en_ceguera.call()

		ceguera_alcanzada.emit.call_deferred()
		oscuridad_iniciada.emit.call_deferred()
		oscuridad_terminada.emit.call_deferred()
		niebla_disipada.emit.call_deferred()
		return

	var mi_token := transicion_ctrl.token_transicion + 1

	var dur_cierre: float = t_cierre if t_cierre >= 0.0 else duracion_cierre
	var dur_apertura: float = t_apertura if t_apertura >= 0.0 else duracion_apertura
	var dur_pausa: float = t_pausa if t_pausa >= 0.0 else pausa_oscuridad

	cubrir(dur_cierre)
	await ceguera_alcanzada

	if transicion_ctrl.token_transicion != mi_token or desactivado:
		return

	oscuridad_iniciada.emit()

	if accion_en_ceguera.is_valid():
		accion_en_ceguera.call()

	if dur_pausa > 0.0 and not desactivado:
		var tree := get_tree()
		if tree != null:
			await tree.create_timer(dur_pausa).timeout

	if transicion_ctrl.token_transicion != mi_token or desactivado:
		return

	oscuridad_terminada.emit()
	despejar(dur_apertura)
	await niebla_disipada
