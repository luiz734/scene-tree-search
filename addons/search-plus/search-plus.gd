@tool
extends EditorPlugin

var popup_search: PopupSearch
var tree: Tree
var dict: Dictionary
var shortcut = Shortcut.new()

func _input(event):
	if shortcut.matches_event(event) and event.is_pressed() and not event.is_echo():
		if popup_search.visible:
			pass
		else:
			popup_search.popup_centered()
			popup_search.label.grab_focus()
			popup_search.label.select_all()


func _enter_tree():
	var filter_dock_prefab: PackedScene = load("res://addons/search-plus/filter.tscn")
	popup_search = filter_dock_prefab.instantiate()
	assert(popup_search)
	EditorInterface.get_editor_main_screen().add_child(popup_search)
	popup_search.hide()
	
	var key_event = InputEventKey.new()
	key_event.keycode = KEY_F4
	shortcut.events = [key_event]
	popup_search.set_shorcut(shortcut)
	
	popup_search.result_selected.connect(_on_result_selected)
	scene_changed.connect(_create_tree)
	var root = EditorInterface.get_edited_scene_root()
	if not root:
		print("no root")
		return
	
	_create_tree(root)

func _exit_tree():
	popup_search.queue_free()

func _create_tree(scene_root):
	dict.clear()
	tree = Tree.new()
	tree.button_clicked.connect(on_tree_button_clicked)
	tree.columns = 2
	tree.hide_root = true
	var tree_root = tree.create_item()
	_add_to_tree(scene_root, tree_root, "root")
	_generate_tree(scene_root, tree_root)
	popup_search.set_tree(tree)

func _generate_tree(node: Node, parent: TreeItem):
	var leaf = tree.create_item(parent)
	_add_to_tree(node, leaf, node.name)
	for child in node.get_children():
		_generate_tree(child, leaf)

func _on_result_selected(item):
	if dict.has(item):
		var meta: TreeItemMeta = dict[item]
		EditorInterface.edit_node(meta.node)
		popup_search.hide()

func _add_to_tree(node: Node, tree_node: TreeItem, label: String):
	var meta := TreeItemMeta.new(node)
	tree_node.set_text(0, label)
	var script := node.get_script()
	if script:
		var texture := load("res://addons/search-plus/Script.svg")
		tree_node.add_button(1, texture, 0)
		meta.script_path = script
	var scene_path := node.scene_file_path
	if scene_path != "":
		var texture := load("res://addons/search-plus/PlayScene.svg")
		tree_node.add_button(1, texture, 1)
		meta.scene_path = scene_path
	dict[tree_node] = meta
	
func on_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int):
	if mouse_button_index != 1:
		return
	var meta: TreeItemMeta = dict[item]
	if id == 0:
		print(meta.script_path)
		EditorInterface.edit_script(meta.script_path)
	else:
		print(meta.scene_path)
		EditorInterface.set_main_screen_editor("2D")
		EditorInterface.open_scene_from_path(meta.scene_path)
