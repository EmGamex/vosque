@tool
class_name TestNiebla
extends McpTestSuite

## Suite de pruebas unitarias para la infraestructura modular de niebla:
## ConfiguracionNiebla, NieblaMaterialController, NieblaFocoController,
## NieblaTransicionController y EfectoNieblaMutacion.


func suite_name() -> String:
	return "niebla"


func test_configuracion_niebla_valores_y_reactividad() -> void:
	var cfg := ConfiguracionNiebla.new()
	assert_true(cfg.cantidad_filas >= 2, "cantidad_filas debe ser al menos 2")
	assert_true(cfg.radio_capsula > 0.0, "radio_capsula debe ser positivo")
	assert_true(cfg.largo_capsula > 0.0, "largo_capsula debe ser positivo")
	assert_true(cfg.duracion_cierre > 0.0, "duracion_cierre debe ser mayor a 0")
	assert_true(cfg.duracion_apertura > 0.0, "duracion_apertura debe ser mayor a 0")
	assert_true(cfg.radio_despejado > cfg.radio_cerrado, "radio_despejado debe ser mayor que radio_cerrado")

	# Probar reactividad mediante emit_changed()
	var estado := {"signal_emitida": false}
	cfg.changed.connect(func(): estado["signal_emitida"] = true)
	cfg.cantidad_filas = 10
	assert_true(estado["signal_emitida"], "Modificar una propiedad de ConfiguracionNiebla debe emitir changed")


func test_niebla_material_controller() -> void:
	var mat_ctrl := NieblaMaterialController.new()
	var color_rect := ColorRect.new()
	var shader_res: Shader = load("res://shaders/niebla_mutacion.gdshader") as Shader
	assert_true(shader_res != null, "El shader niebla_mutacion.gdshader debe cargarse")

	var original_mat := ShaderMaterial.new()
	original_mat.shader = shader_res
	color_rect.material = original_mat

	var cfg := ConfiguracionNiebla.new()
	cfg.cantidad_filas = 6
	cfg.radio_despejado = 2.5
	cfg.radio_cerrado = 0.2

	var mat_instanciado: ShaderMaterial = mat_ctrl.inicializar_material(color_rect, false, false, cfg)
	assert_true(mat_instanciado != null, "Debe inicializar un ShaderMaterial")
	assert_ne(mat_instanciado, original_mat, "El material debe ser duplicado en memoria para aislarlo de disco")
	assert_eq(color_rect.material, mat_instanciado, "ColorRect debe tener asignado el material clonado")
	assert_eq(color_rect.mouse_filter, Control.MOUSE_FILTER_IGNORE, "ColorRect debe ignorar eventos de ratón")

	# Parámetros estáticos y dinámicos
	assert_eq(mat_instanciado.get_shader_parameter("cantidad_filas"), 6, "cantidad_filas debe ser 6")
	mat_ctrl.actualizar_radio_interno(0.8)
	assert_eq(mat_instanciado.get_shader_parameter("radio_interno"), 0.8, "radio_interno debe actualizarse a 0.8")
	mat_ctrl.actualizar_densidad(0.75)
	assert_eq(mat_instanciado.get_shader_parameter("densidad_global"), 0.75, "densidad_global debe actualizarse a 0.75")
	mat_ctrl.actualizar_fase_desplazamiento(12.5)
	assert_eq(mat_instanciado.get_shader_parameter("fase_desplazamiento"), 12.5, "fase_desplazamiento debe ser 12.5")
	mat_ctrl.actualizar_foco(Vector2(0.3, 0.4), 1.77)
	assert_eq(mat_instanciado.get_shader_parameter("centro"), Vector2(0.3, 0.4), "centro debe actualizarse")
	assert_eq(mat_instanciado.get_shader_parameter("aspecto"), 1.77, "aspecto debe actualizarse")

	color_rect.free()


func test_niebla_foco_controller() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var foco_ctrl := NieblaFocoController.new()
	var canvas := CanvasLayer.new()
	var root := Node2D.new()
	root.add_child(canvas)

	var dummy_char := CharacterBody2D.new()
	dummy_char.name = "personaje"
	dummy_char.global_position = Vector2(100, 200)
	root.add_child(dummy_char)

	if tree != null and tree.root != null:
		tree.root.add_child(root)

	# 1. Resolución automática buscando "personaje"
	var encontrado: Node2D = foco_ctrl.resolver_jugador(canvas, null)
	assert_true(encontrado != null, "Debe encontrar al jugador en el árbol")
	assert_eq(encontrado, dummy_char, "Debe coincidir con la instancia dummy_char")

	# 2. Resolución manual con prioridad
	var manual_target := Node2D.new()
	root.add_child(manual_target)
	var res_manual: Node2D = foco_ctrl.resolver_jugador(canvas, manual_target)
	assert_eq(res_manual, manual_target, "El objetivo manual debe tener prioridad si es válido")

	# 3. Cálculo de foco y aspecto en canvas
	var calc := foco_ctrl.calcular_foco_y_aspecto(canvas, dummy_char, Vector2(0.5, 0.5), false)
	assert_true(calc.get("valido", false), "El cálculo de foco debe ser válido dentro del árbol")
	assert_true(calc.get("aspecto", 0.0) > 0.0, "La relación de aspecto debe ser positiva")

	if tree != null and tree.root != null and root.get_parent() == tree.root:
		tree.root.remove_child(root)
	root.free()


func test_niebla_transicion_controller_fsm_y_tokens() -> void:
	var trans_ctrl := NieblaTransicionController.new()
	var mat_ctrl := NieblaMaterialController.new()
	var cfg := ConfiguracionNiebla.new()
	cfg.velocidad_desplazamiento = 0.5
	cfg.radio_despejado = 2.0
	cfg.radio_cerrado = 0.1

	var canvas := CanvasLayer.new()
	var color_rect := ColorRect.new()
	var shader_res: Shader = load("res://shaders/niebla_mutacion.gdshader") as Shader
	var mat := ShaderMaterial.new()
	mat.shader = shader_res
	color_rect.material = mat
	canvas.add_child(color_rect)
	mat_ctrl.inicializar_material(color_rect, false, false, cfg)

	var root := Node2D.new()
	root.add_child(canvas)

	# Estado inicial
	assert_eq(trans_ctrl.fase_actual, NieblaTransicionController.Fase.DESPEJADO, "Debe iniciar en DESPEJADO")
	assert_false(trans_ctrl.animando, "No debe estar animando inicialmente")

	# Acumulación de fase monotónica continua
	var fase_inicial: float = trans_ctrl.fase_desplazamiento
	trans_ctrl.velocidad_actual = 0.5
	trans_ctrl.actualizar_proceso(0.1, mat_ctrl)
	assert_true(trans_ctrl.fase_desplazamiento > fase_inicial, "fase_desplazamiento debe avanzar según delta y velocidad")

	# Probar token y descarte de llamadas concurrentes
	var token_antes: int = trans_ctrl.token_transicion
	var senales := {"ceguera": false, "disipada": false}
	trans_ctrl.cubrir(canvas, 0.05, cfg, mat_ctrl, false, func(): senales["ceguera"] = true)
	assert_ne(trans_ctrl.token_transicion, token_antes, "cubrir() debe incrementar token_transicion")
	assert_eq(trans_ctrl.fase_actual, NieblaTransicionController.Fase.CERRANDO, "Fase debe ser CERRANDO")

	# Interrumpir con abortar_y_limpiar()
	trans_ctrl.abortar_y_limpiar(mat_ctrl, cfg, func(): pass, func(): pass, func(): pass)
	assert_eq(trans_ctrl.fase_actual, NieblaTransicionController.Fase.DESPEJADO, "Tras abortar debe volver a DESPEJADO")
	assert_false(trans_ctrl.animando, "No debe estar animando tras abortar")

	root.free()


func test_efecto_niebla_mutacion_fachada_e_integracion() -> void:
	var escena_niebla: PackedScene = load("res://escenas/efectos/niebla_mutacion.tscn") as PackedScene
	assert_true(escena_niebla != null, "niebla_mutacion.tscn debe poder cargarse")

	var efecto: EfectoNieblaMutacion = escena_niebla.instantiate() as EfectoNieblaMutacion
	assert_true(efecto != null, "Debe instanciarse EfectoNieblaMutacion")
	assert_true(efecto.material_ctrl != null, "Debe poseer NieblaMaterialController")
	assert_true(efecto.foco_ctrl != null, "Debe poseer NieblaFocoController")
	assert_true(efecto.transicion_ctrl != null, "Debe poseer NieblaTransicionController")
	assert_true(efecto.config != null, "Debe tener asignado un ConfiguracionNiebla por defecto")

	var root := Node2D.new()
	root.add_child(efecto)
	efecto.add_to_group("modo_test")
	efecto._ready()

	assert_false(efecto.visible, "Debe iniciar invisible en reposo")
	assert_false(efecto.is_processing(), "Process debe estar inactivo en reposo")

	# Ciclo completo de transición con señales
	var ceguera_recibida := false
	var disipada_recibida := false
	var osc_inicio := false
	var osc_fin := false

	efecto.ceguera_alcanzada.connect(func(): ceguera_recibida = true, CONNECT_ONE_SHOT)
	efecto.oscuridad_iniciada.connect(func(): osc_inicio = true, CONNECT_ONE_SHOT)
	efecto.oscuridad_terminada.connect(func(): osc_fin = true, CONNECT_ONE_SHOT)
	efecto.niebla_disipada.connect(func(): disipada_recibida = true, CONNECT_ONE_SHOT)

	await efecto.ejecutar_transicion(Callable(), 0.02, 0.02, 0.01)

	assert_true(ceguera_recibida, "Señal ceguera_alcanzada debe ser emitida")
	assert_true(osc_inicio, "Señal oscuridad_iniciada debe ser emitida")
	assert_true(osc_fin, "Señal oscuridad_terminada debe ser emitida")
	assert_true(disipada_recibida, "Señal niebla_disipada debe ser emitida")
	assert_eq(efecto.fase_actual, EfectoNieblaMutacion.Fase.DESPEJADO, "Fase final debe ser DESPEJADO")

	root.free()
