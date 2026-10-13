# Normas del Proyecto Godot (Vosque)

## Uso Obligatorio del MCP para Escenas y Recursos
- **Prohibición de edición directa de escenas y recursos:** NUNCA crees ni edites archivos de escena (`.tscn`), recursos (`.tres`), jerarquías de nodos, propiedades o mapas de entrada manipulando archivos crudos directamente en disco con herramientas de escritura de archivos.
- **Uso estricto de herramientas MCP (`godot-ai`):**
  - **Escenas:** Usa `scene_manage` (para `create`, `save_as`, `get_roots`), `scene_open` y `scene_save`.
  - **Nodos y Árbol de Escena:** Usa `node_create`, `node_set_property`, `node_manage`, `node_find` y `node_get_properties`.
  - **Recursos y Configuración:** Usa `resource_manage`, `input_map_manage`, `project_manage`.
- **Código GDScript (`.gd`):** La creación y modificación de scripts puede realizarse mediante `script_create` o `script_patch` (las cuales validan la sintaxis con el compilador en vivo de Godot) o herramientas de edición de código preservando la integridad del script.
