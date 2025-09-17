extends Resource
class_name TreeItemMeta

var node: Node
var script_path
var scene_path

func _init(node: Node) -> void:
	self.node = node
