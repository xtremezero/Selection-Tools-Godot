@tool
extends EditorPlugin

class SelectionContextMenu extends EditorContextMenuPlugin:
	var editor: EditorInterface
	var plugin_ref: EditorPlugin

	func _init(p_editor: EditorInterface, p_plugin: EditorPlugin):
		editor = p_editor
		plugin_ref = p_plugin

	func _popup_menu(paths: PackedStringArray):
		var submenu = PopupMenu.new()
		var items = plugin_ref.get_menu_items()
		var theme = editor.get_editor_theme() if editor.has_method("get_editor_theme") else editor.get_base_control().get_theme()

		for i in range(items.size()):
			var label = items[i]["label"]
			var icon_name = items[i]["icon"]
			var shortcut: Shortcut = items[i]["shortcut"]

			submenu.add_shortcut(shortcut, i)
			submenu.set_item_text(i, label)
			if theme and theme.has_icon(icon_name, "EditorIcons"):
				submenu.set_item_icon(i, theme.get_icon(icon_name, "EditorIcons"))

		submenu.id_pressed.connect(func(id: int):
			var callable: Callable = items[id]["callable"]
			callable.call(paths)
		)

		var main_icon = theme.get_icon("Node", "EditorIcons") if theme and theme.has_icon("Node", "EditorIcons") else null
		add_context_submenu_item("Selection Tools", submenu, main_icon)


var context_menu_plugin: EditorContextMenuPlugin
var menu_items: Array = []

func _enter_tree():
	_setup_menu_items()
	context_menu_plugin = SelectionContextMenu.new(get_editor_interface(), self)
	add_context_menu_plugin(EditorContextMenuPlugin.CONTEXT_SLOT_SCENE_TREE, context_menu_plugin)

func _exit_tree():
	if context_menu_plugin:
		remove_context_menu_plugin(context_menu_plugin)
		context_menu_plugin = null

func _setup_menu_items():
	menu_items = [
		{
			"label": "Select Hierarchy",
			"callable": _select_hierarchy,
			"icon": "Node",
			"shortcut": _create_shortcut(KEY_BRACKETRIGHT, false, true, false) # Shift + ] (Blender Select Hierarchy)
		},
		{
			"label": "Select Children",
			"callable": _select_children,
			"icon": "Node",
			"shortcut": _create_shortcut(KEY_BRACKETRIGHT, false, false, false) # ] (Blender Select Children)
		},
		{
			"label": "Select Parent",
			"callable": _select_parent,
			"icon": "Node",
			"shortcut": _create_shortcut(KEY_BRACKETLEFT, false, false, false) # [ (Blender Select Parent)
		},
		{
			"label": "Select Siblings",
			"callable": _select_siblings,
			"icon": "NodePath",
			"shortcut": _create_shortcut(KEY_G, false, true, true) # Alt + Shift + G (Blender Select Siblings)
		},
		{
			"label": "Select Similar (Type)",
			"callable": _select_same_type,
			"icon": "Script",
			"shortcut": _create_shortcut(KEY_G, false, true, false) # Shift + G (Blender Select Similar Type)
		},
		{
			"label": "Invert Selection",
			"callable": _invert_selection,
			"icon": "Loop",
			"shortcut": _create_shortcut(KEY_I, true, false, false) # Ctrl + I (Blender Invert)
		},
		{
			"label": "Select All",
			"callable": _select_all,
			"icon": "Group",
			"shortcut": _create_shortcut(KEY_A, false, false, false) # A (Blender Select All)
		},
		{
			"label": "Deselect All",
			"callable": _deselect_all,
			"icon": "Clear",
			"shortcut": _create_shortcut(KEY_A, false, false, true) # Alt + A (Blender Deselect All)
		}
	]

func get_menu_items() -> Array:
	return menu_items

func _create_shortcut(key: Key, ctrl: bool, shift: bool, alt: bool) -> Shortcut:
	var shortcut = Shortcut.new()
	var event = InputEventKey.new()
	event.keycode = key
	event.ctrl_pressed = ctrl
	event.shift_pressed = shift
	event.alt_pressed = alt
	shortcut.events.append(event)
	return shortcut

func _should_bypass_shortcuts() -> bool:
	# 1. Bypass if any mouse button is currently held down (Fly mode, Pan, Orbit, Gizmo Drag)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
	or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE) \
	or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		return true

	# 2. Bypass if no edited scene is open
	if not get_editor_interface().get_edited_scene_root():
		return true

	var focus = get_viewport().gui_get_focus_owner()
	if focus:
		# 3. Bypass if focused on text or input controls
		if focus is LineEdit or focus is TextEdit or focus is CodeEdit or focus is SpinBox or focus is OptionButton:
			return true

		# 4. Bypass if focus is inside a modal window or popup dialog
		var window = focus.get_window()
		if window and (window is Popup or window is AcceptDialog or window != get_viewport()):
			return true

	return false

func _input(event: InputEvent):
	if not event is InputEventKey or not event.is_pressed() or event.is_echo():
		return

	if _should_bypass_shortcuts():
		return

	for item in menu_items:
		var shortcut: Shortcut = item["shortcut"]
		if shortcut and shortcut.matches_event(event):
			var callable: Callable = item["callable"]
			callable.call()
			get_viewport().set_input_as_handled()
			break

# --- Selection Logic ---

func _get_selection() -> EditorSelection:
	return get_editor_interface().get_selection()

func _select_hierarchy(_paths = null):
	var selection = _get_selection()
	for node in selection.get_selected_nodes():
		_recursive_select(node, selection)

func _recursive_select(parent: Node, selection: EditorSelection):
	for child in parent.get_children():
		selection.add_node(child)
		_recursive_select(child, selection)

func _select_children(_paths = null):
	var selection = _get_selection()
	for node in selection.get_selected_nodes():
		for child in node.get_children():
			selection.add_node(child)

func _select_parent(_paths = null):
	var selection = _get_selection()
	var selected_nodes = selection.get_selected_nodes()
	if selected_nodes.is_empty():
		return
	var parents_to_select = []
	var scene_root = get_editor_interface().get_edited_scene_root()
	for node in selected_nodes:
		var parent = node.get_parent()
		if parent and parent != scene_root.get_parent():
			parents_to_select.append(parent)
	selection.clear()
	for p in parents_to_select:
		selection.add_node(p)

func _select_siblings(_paths = null):
	var selection = _get_selection()
	var selected_nodes = selection.get_selected_nodes()
	for node in selected_nodes:
		var parent = node.get_parent()
		if parent:
			for sibling in parent.get_children():
				selection.add_node(sibling)

func _select_same_type(_paths = null):
	var selection = _get_selection()
	var selected_nodes = selection.get_selected_nodes()
	if selected_nodes.is_empty():
		return
	var target_classes = {}
	for node in selected_nodes:
		target_classes[node.get_class().to_lower()] = true

	var root = get_editor_interface().get_edited_scene_root()
	if root:
		_recursive_select_by_class(root, target_classes, selection)

func _recursive_select_by_class(node: Node, target_classes: Dictionary, selection: EditorSelection):
	if target_classes.has(node.get_class().to_lower()):
		selection.add_node(node)
	for child in node.get_children():
		_recursive_select_by_class(child, target_classes, selection)

func _invert_selection(_paths = null):
	var selection = _get_selection()
	var currently_selected = selection.get_selected_nodes()
	var root = get_editor_interface().get_edited_scene_root()
	if not root:
		return

	var selected_set = {}
	for n in currently_selected:
		selected_set[n] = true

	selection.clear()
	_recursive_invert(root, selected_set, selection)

func _recursive_invert(node: Node, selected_set: Dictionary, selection: EditorSelection):
	if not selected_set.has(node):
		selection.add_node(node)
	for child in node.get_children():
		_recursive_invert(child, selected_set, selection)

func _select_all(_paths = null):
	var root = get_editor_interface().get_edited_scene_root()
	if not root:
		return
	var selection = _get_selection()
	selection.add_node(root)
	_recursive_select(root, selection)

func _deselect_all(_paths = null):
	_get_selection().clear()
