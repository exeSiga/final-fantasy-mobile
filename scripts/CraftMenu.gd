extends Control

@onready var _recipe_list: VBoxContainer = $Panel/VBox/RecipeList
@onready var _status_lbl: Label = $Panel/VBox/StatusLabel

func _ready() -> void:
	$Panel/VBox/CloseButton.pressed.connect(queue_free)
	_build_recipes()

func _build_recipes() -> void:
	for c in _recipe_list.get_children():
		c.queue_free()
	for i in GameManager.CRAFT_RECIPES.size():
		var recipe: Dictionary = GameManager.CRAFT_RECIPES[i]
		var row := HBoxContainer.new()
		var lbl := Label.new()
		var can_craft: bool = _can_craft(recipe)
		var ing_text: String = ""
		for ing_path in recipe.ingredients:
			var mat_item = load(ing_path)
			var needed: int = recipe.ingredients[ing_path]
			var have: int = GameManager.inventory.get(ing_path, 0)
			var mat_name: String = mat_item.item_name if mat_item != null else "?"
			ing_text += "%s x%d/%d  " % [mat_name, have, needed]
		lbl.text = "%s\n%s" % [recipe.name, ing_text]
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 24)
		var clr := Color(0.3, 1.0, 0.5, 1) if can_craft else Color(0.7, 0.7, 0.7, 1)
		lbl.add_theme_color_override("font_color", clr)
		var btn := Button.new()
		btn.text = "Craft"
		btn.add_theme_font_size_override("font_size", 26)
		btn.custom_minimum_size = Vector2(130, 60)
		btn.disabled = not can_craft
		btn.pressed.connect(_on_craft.bind(i))
		row.add_child(lbl)
		row.add_child(btn)
		_recipe_list.add_child(row)

func _can_craft(recipe: Dictionary) -> bool:
	for ing_path in recipe.ingredients:
		var needed: int = recipe.ingredients[ing_path]
		if GameManager.inventory.get(ing_path, 0) < needed:
			return false
	return true

func _on_craft(recipe_idx: int) -> void:
	if GameManager.craft(recipe_idx):
		var recipe_name: String = GameManager.CRAFT_RECIPES[recipe_idx].name
		_status_lbl.text = "Crafted: %s!" % recipe_name
		_build_recipes()
	else:
		_status_lbl.text = "Not enough materials!"
	await get_tree().create_timer(1.5).timeout
	_status_lbl.text = ""
