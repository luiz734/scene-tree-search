@tool
extends PopupPanel
class_name PopupSearch

# Emited when users click on aa tree item.
signal result_selected
# Emited when the search query chages.
signal filter_changed

@onready var line_edit: LineEdit = %Label
@onready var button: Button = %Button
@onready var vbox: VBoxContainer = %VBox

var _tree: Tree = null
var shortcut_open_dialog = Shortcut.new()

func show_popup_window():
	popup_centered()
	line_edit.grab_focus()
	line_edit.select_all()

func hide_popup_window():
	hide()

func set_shorcut(shorcut: Shortcut):
	shortcut_open_dialog = shorcut
	
func _input(event):
	var right_event :bool = shortcut_open_dialog.matches_event(event) and event.is_pressed() and not event.is_echo()
	if right_event and visible:
		hide_popup_window()
		
func _ready() -> void:
	line_edit.text_changed.connect(_on_search_changed)


func _on_search_changed(query: String) -> void:
	if not _tree or not _tree.get_root() or query == "":
		return
		
	var root := _tree.get_root()
	var child := root.get_first_child()
	while child:
		_filter_item_recursive(child, query)
		child = child.get_next()


func _is_match(text: String, query: String) -> bool:
	if query.is_empty():
		return false
	return text.to_lower().contains(query.to_lower())


func _filter_item_recursive(item: TreeItem, query: String) -> bool:
	# We first find out if any descendants have a match.
	var any_child_matches := false
	var child := item.get_first_child()
	while child:
		if _filter_item_recursive(child, query):
			any_child_matches = true
		child = child.get_next()

	# Current item
	var self_matches := _is_match(item.get_text(0), query)
	var branch_has_match := self_matches or any_child_matches

	# Apply the visuals
	if branch_has_match:
		item.set_collapsed(false)
		if self_matches:
			item.set_custom_color(0, Color.LIGHT_GRAY) 
		else:
			item.clear_custom_color(0)
	else:
		# If no match was found in this item or any of its children,
		# collapse it and dim it out entirely.
		item.set_collapsed(true)
		item.set_custom_color(0, Color.DIM_GRAY)

	return branch_has_match

func set_tree(tree: Tree):
	if _tree:
		_tree.queue_free()
	_tree = tree
	vbox.add_child(tree)
	tree.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree.item_selected.connect(func():
		var item := tree.get_selected()
		result_selected.emit(item)
	)
