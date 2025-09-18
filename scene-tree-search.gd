@tool
extends EditorPlugin

var popup_search: PopupSearch
var tree: Tree
# Maps TreeItem to TreeItemMeta
# TreeItemMeta contains reference to node, script_path and scene_path
var metadata_dict: Dictionary
var shortcut = Shortcut.new()

var texture_script = load("res://addons/scene-tree-search/assets/Script.svg")
var texture_playscene = load("res://addons/scene-tree-search/assets/PlayScene.svg")

const POPUP_FILTER_PREFAB_PATH = "res://addons/scene-tree-search/src/popup_seach.tscn"
const DEFAULT_KEYBIND = KEY_F4
const BUTTON_SCRIPT_ID = 0
const BUTTON_SCENE_ID = 1

func _input(event):
	var right_event = shortcut.matches_event(event) and event.is_pressed() and not event.is_echo()
	if right_event and not popup_search.visible:
		popup_search.show_popup_window()

func _enter_tree():
	var popup_search_prefab: PackedScene = load(POPUP_FILTER_PREFAB_PATH)
	popup_search = popup_search_prefab.instantiate()
	assert(popup_search, "popup search path is incorrect")
	EditorInterface.get_editor_main_screen().add_child(popup_search)
	popup_search.hide_popup_window()
	
	var key_event = InputEventKey.new()
	key_event.keycode = DEFAULT_KEYBIND
	shortcut.events = [key_event]
	popup_search.set_shorcut(shortcut)
	
	popup_search.result_selected.connect(_on_result_selected)
	scene_changed.connect(_create_tree)
	var root = EditorInterface.get_edited_scene_root()
	# When the engine opens no scene is loaded yet
	if root:
		_create_tree(root)

func _exit_tree():
	if popup_search and is_instance_valid(popup_search):
		popup_search.queue_free()

func _create_tree(scene_root):
	metadata_dict.clear()
	tree = Tree.new()
	tree.button_clicked.connect(on_tree_button_clicked)
	tree.columns = 1
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

func _add_to_tree(node: Node, tree_node: TreeItem, label: String):
	var meta := TreeItemMeta.new(node)
	tree_node.set_text(0, label)
	var script := node.get_script()
	if script:
		#var texture := load("res://addons/search-plus/Script.svg")
		tree_node.add_button(0, texture_script, BUTTON_SCRIPT_ID)
		meta.script_path = script
	var scene_path := node.scene_file_path
	if scene_path != "":
		#var texture := load("res://addons/search-plus/PlayScene.svg")
		tree_node.add_button(0, texture_playscene, BUTTON_SCENE_ID)
		meta.scene_path = scene_path
	metadata_dict[tree_node] = meta
	
# When the user cliks on a TreeItem
func _on_result_selected(item):
	if metadata_dict.has(item):
		var meta: TreeItemMeta = metadata_dict[item]
		EditorInterface.edit_node(meta.node)
		popup_search.hide_popup_window()

# When the user cliks on a button on a TreeItem
func on_tree_button_clicked(item: TreeItem, column: int, id: int, mouse_button_index: int):
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return
	var meta: TreeItemMeta = metadata_dict[item]

	if id == BUTTON_SCRIPT_ID:
		#print(meta.script_path)
		EditorInterface.set_main_screen_editor("Script")
		EditorInterface.edit_script(meta.script_path)
		popup_search.hide_popup_window()
	elif id == BUTTON_SCENE_ID:
		#print(meta.scene_path)
		EditorInterface.set_main_screen_editor("2D")
		EditorInterface.open_scene_from_path(meta.scene_path)
		popup_search.hide_popup_window()
	else:
		assert(false, "invalid id")
