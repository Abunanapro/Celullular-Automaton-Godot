extends MenuButton

var locales: PackedStringArray = []

func _ready() -> void:
	locales = TranslationServer.get_loaded_locales()
	for i in locales.size():
		get_popup().add_item(TranslationServer.get_language_name(locales[i]), i)
	
	get_popup().id_pressed.connect(_on_language_selected)

func _on_language_selected(id: int) -> void:
	var lang = locales[id]
	TranslationServer.set_locale(lang)
