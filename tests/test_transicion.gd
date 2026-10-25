@tool
class_name TestTransicion
extends McpTestSuite

## Pruebas unitarias para la arquitectura de TransicionEscenas (Patrón Mediador).

func suite_name() -> String:
	return "transicion"


func _crear_transicion() -> TransicionEscenas:
	var escena: PackedScene = load("res://escenas/transicion.tscn")
	var transicion: TransicionEscenas = escena.instantiate() as TransicionEscenas
	transicion._ready()
	return transicion


func test_instanciacion_y_nodos_base() -> void:
	var transicion: TransicionEscenas = _crear_transicion()
	assert_true(transicion != null, "La escena transicion.tscn debe instanciarse")

	var velo: ColorRect = transicion.get_node_or_null("Velo") as ColorRect
	assert_true(velo != null, "Debe existir el nodo Velo (ColorRect)")

	var anim: AnimationPlayer = transicion.get_node_or_null("Anim") as AnimationPlayer
	assert_true(anim != null, "Debe existir el nodo Anim (AnimationPlayer)")

	assert_true(anim.has_animation("iris_cerrar"), "Anim debe tener 'iris_cerrar'")
	assert_true(anim.has_animation("iris_abrir"), "Anim debe tener 'iris_abrir'")
	assert_true(anim.has_animation("RESET"), "Anim debe tener 'RESET'")

	transicion.free()


func test_propiedad_mediadora_progreso() -> void:
	var transicion: TransicionEscenas = _crear_transicion()
	var velo: ColorRect = transicion.get_node("Velo") as ColorRect
	var mat: ShaderMaterial = velo.material as ShaderMaterial

	transicion.progreso = 0.5
	assert_eq(transicion.progreso, 0.5, "El progreso del nodo debe ser 0.5")

	var prog_shader = mat.get_shader_parameter("progress")
	assert_true(is_equal_approx(prog_shader, 0.5), "El progreso en el shader debe ser 0.5")

	transicion.progreso = 1.0
	prog_shader = mat.get_shader_parameter("progress")
	assert_true(is_equal_approx(prog_shader, 1.0), "Progreso 1.0 en shader (negro completo)")

	transicion.progreso = 0.0
	prog_shader = mat.get_shader_parameter("progress")
	assert_true(is_equal_approx(prog_shader, 0.0), "Progreso 0.0 en shader (pantalla despejada)")

	transicion.free()


func test_ajustar_centro() -> void:
	var transicion: TransicionEscenas = _crear_transicion()
	var velo: ColorRect = transicion.get_node("Velo") as ColorRect
	var mat: ShaderMaterial = velo.material as ShaderMaterial

	var centro_prueba := Vector2(0.3, 0.7)
	transicion.centro = centro_prueba

	var centro_shader = mat.get_shader_parameter("center")
	assert_eq(centro_shader, centro_prueba, "El centro en el shader debe coincidir")

	# Restaurar al centro
	transicion.centro = Vector2(0.5, 0.5)
	assert_eq(mat.get_shader_parameter("center"), Vector2(0.5, 0.5), "Centro restaurado a 0.5, 0.5")

	transicion.free()


func test_bloqueo_input() -> void:
	var transicion: TransicionEscenas = _crear_transicion()
	var velo: ColorRect = transicion.get_node("Velo") as ColorRect

	transicion.bloquear_input(true)
	assert_eq(velo.mouse_filter, Control.MOUSE_FILTER_STOP, "Mouse filter debe bloquear clicks")

	transicion.bloquear_input(false)
	assert_eq(velo.mouse_filter, Control.MOUSE_FILTER_IGNORE, "Mouse filter debe ignorar clicks")

	transicion.free()
