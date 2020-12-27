tool
extends EditorPlugin

var editor
var selection
var dock


func get_plugin_name():
	return "Selection tools"


func _enter_tree():
	dock = preload("res://addons/selectionTools/Resources/SelectionTools.tscn").instance()
	dock.editor = get_editor_interface()
	dock.selection =  get_editor_interface().get_selection()
	add_control_to_bottom_panel(dock,"Selection Tools")

	get_editor_interface().get_selection().get_selected_nodes()
func _exit_tree():
    # Clean-up of the plugin goes here.
    # Remove the dock.
    remove_control_from_bottom_panel(dock)
    # Erase the control from the memory.
    dock.free()
