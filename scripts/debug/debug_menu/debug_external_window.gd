class_name DebugExternalWindow
extends Window

## Ventana nativa secundaria del sistema operativo para alojar el Debug Workspace (Pop-out).

signal cierre_solicitado

var cfg_referencia: Node


func _init() -> void:
	title = "Vosque // Debug Workspace"
	size = Vector2i(1120, 750)
	min_size = Vector2i(640, 420)
	transient = false
	exclusive = false
	visible = false

	close_requested.connect(_on_close_requested)
	size_changed.connect(_on_geometria_modificada)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_POSITION_CHANGED:
		_on_geometria_modificada()


func inicializar_geometria(cfg: Node) -> void:
	cfg_referencia = cfg
	if cfg == null:
		return
	if "ventana_externa_pos" in cfg and cfg.ventana_externa_pos != Vector2i.ZERO:
		position = cfg.ventana_externa_pos
	if "ventana_externa_size" in cfg and cfg.ventana_externa_size != Vector2i.ZERO:
		size = cfg.ventana_externa_size


func _on_close_requested() -> void:
	hide()
	emit_signal("cierre_solicitado")


func _on_geometria_modificada() -> void:
	if cfg_referencia != null and cfg_referencia.has_method("guardar_geometria_ventana_externa"):
		cfg_referencia.guardar_geometria_ventana_externa(position, size)
