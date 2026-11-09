extends SceneTree

# Compila todos os .gd do projeto com os autoloads registrados (o --check-only --script do 4.7.2 nao os carrega).
# Usado por .verify.mjs: `<godot> --headless --path . -s res://.verify-compile.gd`.

var failed := 0
var total := 0

func _initialize() -> void:
	_scan("res://")
	print("VERIFY-COMPILE scripts=", total, " falhas=", failed)
	quit(1 if failed > 0 else 0)

func _scan(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not entry.begins_with("."):
			var full := dir_path.path_join(entry)
			if dir.current_is_dir():
				if entry != "addons" and entry != "export":
					_scan(full)
			elif entry.ends_with(".gd"):
				total += 1
				var script := load(full) as GDScript
				if script == null or not script.can_instantiate():
					failed += 1
					push_error("falha ao compilar " + full)
		entry = dir.get_next()
	dir.list_dir_end()
