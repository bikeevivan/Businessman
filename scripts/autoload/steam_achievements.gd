extends Node

const ACHIEVEMENT_WIN: String = "ACH_WIN_100000"

func unlock(api_name: String) -> void:
	if not Engine.has_singleton("Steam"):
		print("Steam not available, achievement skipped: ", api_name)
		return
	var steam: Object = Engine.get_singleton("Steam")
	if steam.has_method("setAchievement"):
		steam.call("setAchievement", api_name)
	if steam.has_method("storeStats"):
		steam.call("storeStats")
	print("Steam achievement unlocked: ", api_name)
