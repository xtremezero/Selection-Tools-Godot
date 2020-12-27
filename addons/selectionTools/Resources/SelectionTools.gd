tool
extends Control


var editor
var selection
var current_selection=[]

func _ready():
	pass

func select_children(root):
	var node = root
	for N in node.get_children():
		if N.get_child_count() > 0:
			selection.add_node(N)
			select_children(N)
		else:
			selection.add_node(N)

func deselect_children(root):
	var node = root
	for N in node.get_children():
		if N.get_child_count() > 0:
			selection.remove_node(N)
			deselect_children(N)
		else:
			selection.remove_node(N)

func deselect_all():
	for i in selection.get_selected_nodes():
		selection.remove_node(i)

func select_all():
	var root = editor.get_edited_scene_root()
	selection.add_node(root)
	for i in selection.get_selected_nodes():
		select_children(i)

func select_name(root,name):
	var node = root
	if name in root.name:
		selection.add_node(root)
	for N in node.get_children():
		if N.get_child_count() > 0:
			if name.to_lower() in N.name.to_lower():
				selection.add_node(N)
			select_name(N,name)
		else:
			if name.to_lower() in N.name.to_lower():
				selection.add_node(N)
	
func deselect_name(name):
	for i in selection.get_selected_nodes():
		if name.to_lower() in i.name.to_lower():
			selection.remove_node(i)

func select_type(root,name):
	var node = root
	if name.to_lower() == root.get_class().to_lower():
		selection.add_node(root)
	for N in node.get_children():
		if N.get_child_count() > 0:
			if name.to_lower() == N.get_class().to_lower():
				selection.add_node(N)
			select_type(N,name)
		else:
			if name.to_lower() == N.get_class().to_lower():
				selection.add_node(N)

func deselect_type(name):
	for i in selection.get_selected_nodes():
		if name.to_lower() == i.get_class().to_lower():
			selection.remove_node(i)

func select_invert(root):
	var node = root
	
	if not (root in current_selection): 
		selection.add_node(root)
	for N in node.get_children():
		if N.get_child_count() > 0:
			if not (N in current_selection): 
				selection.add_node(N)
			
			select_invert(N)
		else:
			if not (N in current_selection):
				selection.add_node(N)
	
# SIGNALS ####################

func _on_selectall_pressed():
	select_all()


func _on_deselectall_pressed():
	deselect_all()


func _on_deselectchildren_pressed():
	for i in selection.get_selected_nodes():
		deselect_children(i)

func _on_selectchildren_pressed():
	for i in selection.get_selected_nodes():
		select_children(i)

func _on_namefind_pressed():
	if get_node("Panel/OnlyChildren").pressed == false:
		select_name(editor.get_edited_scene_root(),get_node("Panel/namesearch").text)
	else:
		for i in selection.get_selected_nodes():
			select_name(i,get_node("Panel/namesearch").text)

func _on_classfind_pressed():
	if get_node("Panel/OnlyChildren").pressed == false:
		select_type(editor.get_edited_scene_root(),get_node("Panel/typesearch").text)
	else:
		for i in selection.get_selected_nodes():
			select_type(i,get_node("Panel/typesearch").text)

func _on_namefind2_pressed():
	deselect_name(get_node("Panel/namesearch").text)

func _on_classfind2_pressed():
	deselect_type(get_node("Panel/typesearch").text)


func _on_selectInvert_pressed():
	current_selection = selection.get_selected_nodes()
	deselect_all()
	select_invert(editor.get_edited_scene_root())
	current_selection.clear()
