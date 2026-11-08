class_name DebugDockController
extends RefCounted

## Controlador para la Barra Dock superior del DebugMenu.
## Conecta botones de acceso a ventanas, selector de presets, pausa y cierre.

signal modo_ocultar_solicitado
signal ordenar_mosaico_solicitado
signal preset_seleccionado(index: int)

var barra_dock: PanelContainer
var btn_dock_jugador: Button
var btn_dock_fisicas: Button
var btn_dock_escenario: Button
var btn_dock_enemigo: Button
var btn_dock_audio: Button
var btn_dock_sistema: Button
var option_presets: OptionButton
var btn_ordenar_mosaico: Button
var check_pausar: CheckBox
var btn_cerrar_dock: Button


func vincular_nodos(dock: PanelContainer) -> void:
	barra_dock = dock
	if barra_dock == null:
		return
	btn_dock_jugador = barra_dock.get_node_or_null("HBoxDock/BtnDockJugador") as Button
	btn_dock_fisicas = barra_dock.get_node_or_null("HBoxDock/BtnDockFisicas") as Button
	btn_dock_escenario = barra_dock.get_node_or_null("HBoxDock/BtnDockEscenario") as Button
	btn_dock_enemigo = barra_dock.get_node_or_null("HBoxDock/BtnDockEnemigo") as Button
	btn_dock_audio = barra_dock.get_node_or_null("HBoxDock/BtnDockAudio") as Button
	btn_dock_sistema = barra_dock.get_node_or_null("HBoxDock/BtnDockSistema") as Button
	option_presets = barra_dock.get_node_or_null("HBoxDock/OptionPresets") as OptionButton
	btn_ordenar_mosaico = barra_dock.get_node_or_null("HBoxDock/BtnOrdenarMosaico") as Button
	check_pausar = barra_dock.get_node_or_null("HBoxDock/CheckPausar") as CheckBox
	btn_cerrar_dock = barra_dock.get_node_or_null("HBoxDock/BtnCerrarDock") as Button


func inicializar_presets() -> void:
	if option_presets == null:
		return
	option_presets.clear()
	option_presets.add_item("Presets Rápidos...")
	option_presets.add_item("Locomoción & Físicas")
	option_presets.add_item("Caza & Enemigo IA")
	option_presets.add_item("Mundo & Mutación")
	option_presets.add_item("Audio & Sistema")
	option_presets.add_item("Cerrar Todas")


func conectar_eventos(window_mgr: DebugWindowManager, system_ctrl: DebugSystemController, tree: SceneTree) -> void:
	if btn_dock_jugador != null and not btn_dock_jugador.pressed.is_connected(_toggle_win.bind(window_mgr.win_jugador)):
		btn_dock_jugador.pressed.connect(_toggle_win.bind(window_mgr.win_jugador))
	if btn_dock_fisicas != null and not btn_dock_fisicas.pressed.is_connected(_toggle_win.bind(window_mgr.win_fisicas)):
		btn_dock_fisicas.pressed.connect(_toggle_win.bind(window_mgr.win_fisicas))
	if btn_dock_escenario != null and not btn_dock_escenario.pressed.is_connected(_toggle_win.bind(window_mgr.win_escenario)):
		btn_dock_escenario.pressed.connect(_toggle_win.bind(window_mgr.win_escenario))
	if btn_dock_enemigo != null and not btn_dock_enemigo.pressed.is_connected(_toggle_win.bind(window_mgr.win_enemigo)):
		btn_dock_enemigo.pressed.connect(_toggle_win.bind(window_mgr.win_enemigo))
	if btn_dock_audio != null and not btn_dock_audio.pressed.is_connected(_toggle_win.bind(window_mgr.win_audio)):
		btn_dock_audio.pressed.connect(_toggle_win.bind(window_mgr.win_audio))
	if btn_dock_sistema != null and not btn_dock_sistema.pressed.is_connected(_toggle_win.bind(window_mgr.win_sistema)):
		btn_dock_sistema.pressed.connect(_toggle_win.bind(window_mgr.win_sistema))

	if btn_ordenar_mosaico != null and not btn_ordenar_mosaico.pressed.is_connected(_on_ordenar_mosaico):
		btn_ordenar_mosaico.pressed.connect(_on_ordenar_mosaico)
	if btn_cerrar_dock != null and not btn_cerrar_dock.pressed.is_connected(_on_cerrar_dock):
		btn_cerrar_dock.pressed.connect(_on_cerrar_dock)
	if option_presets != null and not option_presets.item_selected.is_connected(_on_preset_item_selected.bind(window_mgr)):
		option_presets.item_selected.connect(_on_preset_item_selected.bind(window_mgr))
	if check_pausar != null and not check_pausar.toggled.is_connected(_on_check_pausar_toggled.bind(system_ctrl, tree)):
		check_pausar.toggled.connect(_on_check_pausar_toggled.bind(system_ctrl, tree))


func _toggle_win(win: DebugWindow) -> void:
	if win != null:
		win.abierta = not win.abierta


func _on_ordenar_mosaico() -> void:
	emit_signal("ordenar_mosaico_solicitado")


func _on_cerrar_dock() -> void:
	emit_signal("modo_ocultar_solicitado")


func _on_preset_item_selected(index: int, window_mgr: DebugWindowManager) -> void:
	window_mgr.aplicar_preset(index)
	emit_signal("preset_seleccionado", index)
	if option_presets != null:
		option_presets.selected = 0


func _on_check_pausar_toggled(toggled_on: bool, system_ctrl: DebugSystemController, tree: SceneTree) -> void:
	if system_ctrl != null and tree != null:
		system_ctrl.toggle_pausa(tree, toggled_on)
