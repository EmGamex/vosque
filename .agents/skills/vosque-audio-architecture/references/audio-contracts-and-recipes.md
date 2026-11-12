# Audio Contracts & Recipes (Vosque)

Documento de soporte técnico y recetas de código para la skill `vosque-audio-architecture`.

---

## 1. Recetas de Integración en GDScript

### 1.1. Invocación Segura de Música desde Gameplay (Sin Acoplamiento Rígido)
En clases como `Maain`, `Enemigo` o controladores de gameplay, acceder siempre comprobando la existencia del singleton en el árbol:

```gdscript
func _obtener_gestor_musica() -> Node:
	if not is_inside_tree():
		return null
	var tree := get_tree()
	if tree == null or tree.root == null:
		return null
	if tree.root.has_node("GestorMusica"):
		return tree.root.get_node("GestorMusica")
	return null

# Ejemplo al recolectar la primera nota:
func _notificar_transicion_supervivencia() -> void:
	var musica := _obtener_gestor_musica()
	if musica != null and musica.has_method("transicionar_a_supervivencia"):
		musica.transicionar_a_supervivencia()

# Ejemplo en captura / jumpscare letal:
func _notificar_jumpscare() -> void:
	var musica := _obtener_gestor_musica()
	if musica != null and musica.has_method("detener_por_jumpscare"):
		musica.detener_por_jumpscare()
```

---

### 1.2. Reanudación de Nightmare Decay en la Pantalla de Game Over
Al instanciarse y activarse `game_over.tscn`:

```gdscript
# En GameOver._ready() o al activarse tras la animación de derrota:
func _activar_audio_game_over() -> void:
	if not Engine.is_editor_hint() and has_node("/root/GestorMusica"):
		get_node("/root/GestorMusica").activar_modo_game_over()

# Al salir de la pantalla de Game Over (Reintentar o Volver al Menú):
func _restaurar_audio_normal() -> void:
	if has_node("/root/GestorMusica"):
		var gm = get_node("/root/GestorMusica")
		gm.restaurar_parametros_normales()
		gm.reproducir_menu_o_tutorial()
```

---

### 1.3. Sincronización de Volumen Base desde Ajustes / Sliders
Al modificar el slider de música en `MenuOpciones` o al cargar datos desde `GestorPersistencia`:

```gdscript
func _aplicar_volumen_musica(db: float) -> void:
	var idx := AudioServer.get_bus_index(&"musica")
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, db)

	# Sincronización obligatoria para que GestorMusica no sobrescriba el volumen en su _process
	if has_node("/root/GestorMusica"):
		var gm: Node = get_node("/root/GestorMusica")
		if gm.has_method("establecer_volumen_base"):
			gm.establecer_volumen_base(db)
		elif "config" in gm and gm.config is ConfiguracionMusica:
			gm.config.volumen_base_db = db
```

---

### 1.4. Disparo Seguro de SFX de Interfaz (`GestorAudioUI`)
Tanto en modo runtime como en tests o herramientas `@tool`:

```gdscript
# Navegación entre opciones:
ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.PAUSA_NAVEGAR)

# Confirmación de botón:
ControladorAudioUI.emitir_seguro(self, ControladorAudioUI.EventoUI.PAUSA_ACEPTAR)

# Auto-vinculación declarativa de botón:
GestorAudioUI.vincular_boton($BotonOpcion, true) # true para tema de pausa, false para menú inicio
```

---

## 2. Utilidad Canónica `ConfiguradorBusesYMusica`

Para regenerar o recalibrar los recursos nativos desde GDScript sin depender de manipulación de archivos crudos:

```gdscript
# 1. Regenerar los 5 buses en res://default_bus_layout.tres:
var err_layout := ConfiguradorBusesYMusica.configurar_bus_layout(true)
if err_layout == OK:
	print("Layout de buses configurado con éxito.")

# 2. Regenerar el AudioStreamInteractive en res://sonido/musica/musica_interactiva.tres:
var err_musica := ConfiguradorBusesYMusica.configurar_musica_interactiva()
if err_musica == OK:
	print("Recurso AudioStreamInteractive configurado con éxito.")
```

---

## 3. Checklist de Comandos y Operaciones con MCP `godot-ai`

1. **Inspeccionar buses de audio en runtime:**
   * Usa `test_run` con la suite `gestor_musica` para validar que los 5 buses, sus volúmenes y sus efectos están íntegros.
2. **Consultar o editar propiedades en escenas:**
   * Abre la escena: `scene_open(scene_path="res://escenas/gestor_musica.tscn")`.
   * Lee o edita propiedades: `node_get_properties` / `node_set_property`.
   * Guarda los cambios: `scene_save()`.
3. **Validación de scripts:**
   * Modifica código mediante `script_patch` o herramientas de edición preservando las cabeceras `@tool`, `class_name` e invariantes de proceso.

---

## 4. Batería de Pruebas Automatizadas

Para validar cualquier cambio en el subsistema de audio mediante el MCP `godot-ai`:

```gdscript
# Ejecutar suite de GestorMusica (buses, clips, Nightmare Decay, F3):
test_run(suite="gestor_musica", verbose=true)

# Ejecutar suite de GestorAudioUI (reproductores UI, pitch jitter, eventos):
test_run(suite="gestor_audio_ui", verbose=true)
```
