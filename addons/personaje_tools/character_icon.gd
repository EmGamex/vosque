@tool
extends RefCounted

## Resolución del icono a mostrar en la barra de personaje, sin estado.

const ICONO_POR_DEFECTO := "res://icon.svg"


## Prioridad: icono personalizado > primera textura del personaje > icono por defecto.
static func resolver(
	personalizado: Texture2D, personaje: Node, ruta_por_defecto := ICONO_POR_DEFECTO
) -> Texture2D:
	if personalizado != null:
		return personalizado

	if is_instance_valid(personaje):
		var textura := _buscar_textura(personaje)
		if textura != null:
			return textura

	if ResourceLoader.exists(ruta_por_defecto):
		return load(ruta_por_defecto) as Texture2D
	return null


static func _buscar_textura(nodo: Node) -> Texture2D:
	for hijo in nodo.get_children():
		if hijo is Sprite2D and (hijo as Sprite2D).texture != null:
			return (hijo as Sprite2D).texture
		if hijo is AnimatedSprite2D:
			var textura := _textura_animada(hijo as AnimatedSprite2D)
			if textura != null:
				return textura
		var anidada := _buscar_textura(hijo)
		if anidada != null:
			return anidada
	return null


static func _textura_animada(sprite: AnimatedSprite2D) -> Texture2D:
	var cuadros := sprite.sprite_frames
	if cuadros == null:
		return null
	var animacion := sprite.animation
	if not cuadros.has_animation(animacion) or cuadros.get_frame_count(animacion) == 0:
		return null
	# La barra solo muestra una miniatura estática: con el primer cuadro de la animación actual basta.
	return cuadros.get_frame_texture(animacion, 0)
