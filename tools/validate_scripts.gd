## Statique : charge chaque script .gd du projet et échoue si Godot signale une erreur de parse.
## Remplace `--check-only` (réservé aux builds éditeur, indisponible sur ce binaire — il ne rend
## jamais la main ici, voir check_parse.sh) par un chargement réel de chaque fichier, qui déclenche
## la même compilation statique GDScript et rapporte les mêmes erreurs ("SCRIPT ERROR: Parse Error").
extends SceneTree

func _initialize() -> void:
	# _initialize() (not _init()) — autoload singletons (GameManager, etc.) are only registered
	# as globally resolvable identifiers by this point. Loading scripts in _init() reports every
	# autoload reference as "Identifier not found", which is noise, not a real error.
	var files: Array = []
	_collect_gd_files("res://", files)
	print("Validating %d .gd files..." % files.size())
	for path in files:
		load(path)
	print("Validation pass complete.")
	quit(0)

func _collect_gd_files(dir_path: String, out: Array) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if name.begins_with("."):
			name = dir.get_next()
			continue
		var full_path: String = dir_path.path_join(name)
		if dir.current_is_dir():
			_collect_gd_files(full_path, out)
		elif name.ends_with(".gd"):
			out.append(full_path)
		name = dir.get_next()
	dir.list_dir_end()
