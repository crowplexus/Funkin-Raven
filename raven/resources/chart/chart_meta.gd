class_name ChartMeta extends Resource

@export var authors: Array[String] = []
@export var offset: float = 0.0
@export var skin: UISkin

func get_authors():
	var temp: String = ""
	for i in authors.size(): temp+=authors[i]
	return temp
