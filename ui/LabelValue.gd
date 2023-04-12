@tool
extends HBoxContainer

@onready var name_label = $Label
@onready var value_label = $Value

@export var _label: String = 'Name'
@export var _value: String = 'Value' 

func _enter_tree():
	if OS.has_feature('editor'):
		var error = connect("visibility_changed",Callable(self,"_on_visibility_changed"))
		if error:
			print_debug(error)

func _on_visibility_changed():
	if visible:
		_ready()

# Called when the node enters the scene tree for the first time.
func _ready():
	set_label(_label)
	set_value(_value)

func set_label(text: String) -> void:
	name_label.text = text
	_label = text

func set_value(text: String) -> void:
	value_label.text = text
	_value = text
