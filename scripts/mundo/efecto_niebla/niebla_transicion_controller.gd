@tool
class_name NieblaTransicionController
extends RefCounted

## Controlador especializado en la máquina de estados, acumulación de fase continua y animaciones Tween de niebla.

enum Fase {
	DESPEJADO,
	CERRANDO,
	CEGUERA,
	ABRIENDO
}

var fase_actual: Fase = Fase.DESPEJADO
var animando: bool = false
var token_transicion: int = 0
var fase_desplazamiento: float = 0.0
var velocidad_actual: float = 0.25

var _tween: Tween


func actualizar_proceso(delta: float, material_ctrl: NieblaMaterialController) -> void:
	fase_desplazamiento += delta * velocidad_actual
	if material_ctrl != null:
		material_ctrl.actualizar_fase_desplazamiento(fase_desplazamiento)


func abortar_y_limpiar(
	material_ctrl: NieblaMaterialController,
	config: ConfiguracionNiebla,
	on_ceguera: Callable,
	on_oscuridad_fin: Callable,
	on_disipada: Callable
) -> void:
	token_transicion += 1
	var estaba_en_cierre: bool = (fase_actual == Fase.CERRANDO)
	var estaba_en_apertura: bool = (fase_actual == Fase.ABRIENDO or fase_actual == Fase.CEGUERA)

	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null

	animando = false
	fase_actual = Fase.DESPEJADO
	velocidad_actual = config.velocidad_desplazamiento if config != null else 0.25

	if material_ctrl != null:
		material_ctrl.actualizar_densidad(0.0)
		material_ctrl.actualizar_radio_interno(config.radio_despejado if config != null else 2.0)

	if estaba_en_cierre and on_ceguera.is_valid():
		on_ceguera.call_deferred()
	if estaba_en_apertura:
		if on_oscuridad_fin.is_valid():
			on_oscuridad_fin.call_deferred()
		if on_disipada.is_valid():
			on_disipada.call_deferred()


func cubrir(
	nodo: CanvasLayer,
	duracion: float,
	config: ConfiguracionNiebla,
	material_ctrl: NieblaMaterialController,
	desactivado: bool,
	on_ceguera: Callable
) -> void:
	token_transicion += 1
	var token_actual := token_transicion

	if desactivado:
		fase_actual = Fase.CEGUERA
		if on_ceguera.is_valid():
			on_ceguera.call_deferred()
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null

	animando = true
	fase_actual = Fase.CERRANDO
	nodo.visible = true
	nodo.set_process(true)

	var t: float = duracion if duracion >= 0.0 else (config.duracion_cierre if config != null else 1.2)
	if material_ctrl == null or material_ctrl.material_shader == null:
		animando = false
		fase_actual = Fase.CEGUERA
		if on_ceguera.is_valid():
			on_ceguera.call_deferred()
		return

	var radio_cerrado: float = config.radio_cerrado if config != null else 0.15
	var radio_despejado: float = config.radio_despejado if config != null else 2.0
	var radio_inicial: float = radio_despejado

	var radio_param = material_ctrl.material_shader.get_shader_parameter("radio_interno")
	if radio_param is float and radio_param > radio_cerrado:
		radio_inicial = radio_param

	var dens_param = material_ctrl.material_shader.get_shader_parameter("densidad_global")
	var dens_inicial: float = dens_param if dens_param is float else 0.0

	var vel_base: float = config.velocidad_desplazamiento if config != null else 0.25
	var mult_vel: float = config.multiplicador_velocidad_transicion if config != null else 2.5
	var vel_rapida: float = vel_base * mult_vel

	_tween = nodo.create_tween().set_parallel(true)
	_tween.set_trans(config.tipo_transicion if config != null else Tween.TRANS_SINE)
	_tween.set_ease(config.tipo_ease_cierre if config != null else Tween.EASE_IN_OUT)

	_tween.tween_method(
		func(val: float): material_ctrl.actualizar_radio_interno(val),
		radio_inicial,
		radio_cerrado,
		t
	)
	_tween.tween_method(
		func(val: float): material_ctrl.actualizar_densidad(val),
		dens_inicial,
		1.0,
		t
	)
	_tween.tween_method(
		func(val: float): velocidad_actual = val,
		vel_base,
		vel_rapida,
		t
	)

	_tween.chain().tween_callback(func():
		if token_transicion != token_actual:
			return
		animando = false
		fase_actual = Fase.CEGUERA
		material_ctrl.actualizar_radio_interno(radio_cerrado)
		material_ctrl.actualizar_densidad(1.0)
		velocidad_actual = vel_rapida
		if on_ceguera.is_valid():
			on_ceguera.call()
	)


func despejar(
	nodo: CanvasLayer,
	duracion: float,
	config: ConfiguracionNiebla,
	material_ctrl: NieblaMaterialController,
	desactivado: bool,
	on_disipada: Callable
) -> void:
	token_transicion += 1
	var token_actual := token_transicion

	if desactivado:
		animando = false
		fase_actual = Fase.DESPEJADO
		nodo.visible = false
		nodo.set_process(false)
		if on_disipada.is_valid():
			on_disipada.call_deferred()
		return

	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null

	var t: float = duracion if duracion >= 0.0 else (config.duracion_apertura if config != null else 1.2)
	animando = true
	fase_actual = Fase.ABRIENDO
	nodo.visible = true
	nodo.set_process(true)

	if material_ctrl == null or material_ctrl.material_shader == null:
		animando = false
		fase_actual = Fase.DESPEJADO
		nodo.visible = false
		nodo.set_process(false)
		if on_disipada.is_valid():
			on_disipada.call_deferred()
		return

	var radio_cerrado: float = config.radio_cerrado if config != null else 0.15
	var radio_despejado: float = config.radio_despejado if config != null else 2.0
	var radio_inicial: float = radio_cerrado

	var radio_param = material_ctrl.material_shader.get_shader_parameter("radio_interno")
	if radio_param is float and radio_param < radio_despejado:
		radio_inicial = radio_param

	var dens_param = material_ctrl.material_shader.get_shader_parameter("densidad_global")
	var dens_inicial: float = dens_param if dens_param is float else 1.0

	var vel_base: float = config.velocidad_desplazamiento if config != null else 0.25
	var mult_vel: float = config.multiplicador_velocidad_transicion if config != null else 2.5
	var vel_rapida: float = vel_base * mult_vel

	_tween = nodo.create_tween().set_parallel(true)
	_tween.set_trans(config.tipo_transicion if config != null else Tween.TRANS_SINE)
	_tween.set_ease(config.tipo_ease_apertura if config != null else Tween.EASE_OUT)

	_tween.tween_method(
		func(val: float): material_ctrl.actualizar_radio_interno(val),
		radio_inicial,
		radio_despejado,
		t
	)
	_tween.tween_method(
		func(val: float): material_ctrl.actualizar_densidad(val),
		dens_inicial,
		0.0,
		t
	)
	_tween.tween_method(
		func(val: float): velocidad_actual = val,
		vel_rapida,
		vel_base,
		t
	)

	_tween.chain().tween_callback(func():
		if token_transicion != token_actual:
			return
		animando = false
		fase_actual = Fase.DESPEJADO
		material_ctrl.actualizar_radio_interno(radio_despejado)
		material_ctrl.actualizar_densidad(0.0)
		velocidad_actual = vel_base
		nodo.visible = false
		nodo.set_process(false)
		if on_disipada.is_valid():
			on_disipada.call()
	)
