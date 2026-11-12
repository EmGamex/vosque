# MCP godot-ai Cheatsheet: Payloads de Referencia para Vosque

Esta guía contiene la sintaxis exacta de payloads para invocar herramientas del MCP `godot-ai` mediante `call_mcp_tool(ServerName="godot-ai", ToolName="...", Arguments={...})`.

---

## 1. Gestión de Escenas

### Abrir Escena Existente (`scene_open`)
```json
{
  "path": "res://escenas/core/maain.tscn",
  "force_reload": false
}
```

### Crear Nueva Escena (`scene_manage` - op: "create")
```json
{
  "op": "create",
  "params": {
    "path": "res://escenas/entidades/items/nota.tscn",
    "root_type": "Area2D",
    "root_name": "Nota"
  }
}
```

### Guardar Escena Actual (`scene_save`)
```json
{}
```

### Guardar Como Otra Ruta (`scene_manage` - op: "save_as")
```json
{
  "op": "save_as",
  "params": {
    "path": "res://escenas/entidades/items/nota_variante.tscn"
  }
}
```

### Consultar Raíces Abiertas (`scene_manage` - op: "get_roots")
```json
{
  "op": "get_roots"
}
```

---

## 2. Inspección del Árbol de Escena

### Jerarquía Completa (`scene_get_hierarchy`)
```json
{
  "depth": 10,
  "limit": 100,
  "offset": 0
}
```

### Buscar Nodos por Tipo, Nombre o Grupo (`node_find`)
```json
{
  "type": "Marker2D",
  "group": "puntos_nota"
}
```

### Consultar Propiedades de un Nodo (`node_get_properties`)
```json
{
  "path": "/Maain/Jugador",
  "fields": ["position", "speed", "collision_layer", "collision_mask"]
}
```

---

## 3. Manipulación de Nodos y Propiedades

### Crear Nodo Nativo (`node_create` con `type`)
```json
{
  "parent_path": "/Maain",
  "type": "DirectionalLight2D",
  "name": "LuzAmbiental"
}
```

### Instanciar Subescena (`node_create` con `scene_path`)
*Nota: `type` y `scene_path` son mutuamente excluyentes.*
```json
{
  "parent_path": "/Maain",
  "scene_path": "res://escenas/entidades/enemigo/enemigo.tscn",
  "name": "Enemigo"
}
```

### Modificar Propiedad (`node_set_property`)

#### Vector2 / Vector3
```json
{
  "path": "/Maain/Enemigo",
  "property": "position",
  "value": { "x": -99999.0, "y": -99999.0 }
}
```

#### Color
```json
{
  "path": "/Maain/LuzAmbiental",
  "property": "color",
  "value": "#1a1c23"
}
```

#### NodePath / Export de Nodo (`@export var target: Node2D`)
```json
{
  "path": "/Maain/Camara2D",
  "property": "objetivo_nodo",
  "value": "/Maain/Jugador"
}
```

#### Shape Embebida (`[sub_resource]`)
```json
{
  "path": "/Maain/Jugador/CollisionShape2D",
  "property": "shape",
  "value": {
    "__class__": "CircleShape2D",
    "radius": 24.0
  }
}
```

---

## 4. Estructura del Árbol (`node_manage`)

### Habilitar Editable Children en Instancias
Requerido para modificar propiedades de subnodos pertenecientes a una escena instanciada:
```json
{
  "op": "set_editable_children",
  "params": {
    "path": "/Maain/Jugador",
    "editable": true
  }
}
```

### Reordenar / Mover Nodo entre Hermanos
```json
{
  "op": "move",
  "params": {
    "path": "/Maain/LuzAmbiental",
    "index": 0
  }
}
```

### Reparentar Nodo
```json
{
  "op": "reparent",
  "params": {
    "path": "/Maain/LuzAmbiental",
    "new_parent": "/Maain/Iluminacion"
  }
}
```

### Grupos de Nodos
```json
// Agregar a grupo
{
  "op": "add_to_group",
  "params": {
    "path": "/Maain/PuntoSpawn1",
    "group": "puntos_nota"
  }
}

// Consultar grupos
{
  "op": "get_groups",
  "params": {
    "path": "/Maain/PuntoSpawn1"
  }
}
```

---

## 5. Gestión de Señales (`signal_manage`)

### Listar Señales de un Nodo
```json
{
  "op": "list",
  "params": {
    "path": "/Maain/HUD/BotonPausa"
  }
}
```

### Conectar Señal
```json
{
  "op": "connect",
  "params": {
    "path": "/Maain/HUD/BotonPausa",
    "signal": "pressed",
    "target": "/Maain",
    "method": "_on_boton_pausa_pressed"
  }
}
```

### Desconectar Señal
```json
{
  "op": "disconnect",
  "params": {
    "path": "/Maain/HUD/BotonPausa",
    "signal": "pressed",
    "target": "/Maain",
    "method": "_on_boton_pausa_pressed"
  }
}
```

---

## 6. Recursos (`resource_manage`)

### Crear Recurso .tres Externo
```json
{
  "op": "create",
  "params": {
    "type": "CircleShape2D",
    "resource_path": "res://recursos/colisiones/radio_captura.tres",
    "properties": {
      "radius": 56.0
    }
  }
}
```

### Asignar Recurso Existente a un Nodo
```json
{
  "op": "assign",
  "params": {
    "path": "/Maain/Enemigo/AreaCaptura/CollisionShape2D",
    "property": "shape",
    "resource_path": "res://recursos/colisiones/radio_captura.tres"
  }
}
```

### Auto-ajustar Shape de Colisión a Sprite (`physics_shape_autofit`)
```json
{
  "op": "physics_shape_autofit",
  "params": {
    "path": "/Maain/Nota/CollisionShape2D",
    "source_path": "/Maain/Nota/Sprite2D",
    "shape_type": "rectangle"
  }
}
```

---

## 7. Scripts y Configuración de Proyecto

### Crear y Validar Script (`script_create`)
```json
{
  "path": "res://scripts/core/maain/controlador_ejemplo.gd",
  "content": "class_name ControladorEjemplo\nextends RefCounted\n\nfunc inicializar() -> void:\n\tpass\n"
}
```

### Asociar Script a Nodo (`script_attach`)
```json
{
  "path": "/Maain/Director",
  "script_path": "res://scripts/core/maain/controlador_ejemplo.gd"
}
```

### Configurar Autoload Singleton (`autoload_manage`)
```json
{
  "op": "add",
  "params": {
    "name": "GestorAudio",
    "path": "res://scripts/autoloads/gestor_audio.gd",
    "singleton": true
  }
}
```

### Registrar Acción de Entrada (`input_map_manage`)
```json
// 1. Asegurar acción
{
  "op": "ensure_action",
  "params": {
    "action": "interactuar",
    "deadzone": 0.5
  }
}

// 2. Asociar tecla
{
  "op": "bind_event",
  "params": {
    "action": "interactuar",
    "event_type": "key",
    "keycode": "E"
  }
}
```
