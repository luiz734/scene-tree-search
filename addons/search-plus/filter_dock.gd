@tool
extends PopupPanel
class_name PopupSearch

signal result_selected
signal filter_changed

@onready var label: LineEdit = %Label
@onready var button: Button = %Button
@onready var vbox: VBoxContainer = %VBox

var _tree: Tree = null
var open_dialog = Shortcut.new()

func set_shorcut(shorcut: Shortcut):
	open_dialog = shorcut
	
func _input(event):
	if open_dialog.matches_event(event) and event.is_pressed() and not event.is_echo():
		if visible:
			hide()
		else:
			popup_centered()
			label.grab_focus()
			label.select_all()
	if event.is_action("ui_accept"):
		var item := _tree.get_selected()
		result_selected.emit(item)



func _ready() -> void:
	label.text_changed.connect(on_search_changed)

func on_search_changed(query: String):
	if not _tree:
			return
	var root_item := _tree.get_root()
	var next := root_item.get_next_in_tree()
	while next:
		var node_name := next.get_text(0)
		if node_name.to_lower().contains(query.to_lower()):
			next.set_custom_color(0, Color.LIGHT_GRAY)
		else:
			next.set_custom_color(0, Color.DIM_GRAY)
		next = next.get_next_in_tree()

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
