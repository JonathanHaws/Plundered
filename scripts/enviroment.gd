extends WorldEnvironment

func _ready() -> void:
	environment.adjustment_enabled = true

	environment.adjustment_brightness = Config.load_setting("display", "brightness", environment.adjustment_brightness)
	environment.adjustment_contrast   = Config.load_setting("display", "contrast",   environment.adjustment_contrast)
	environment.adjustment_saturation = Config.load_setting("display", "saturation", environment.adjustment_saturation)

	environment.ssao_enabled   = Config.load_setting("display", "ssao_enabled", environment.ssao_enabled)
	environment.ssao_radius    = Config.load_setting("display", "ssao_radius",  environment.ssao_radius)
	environment.ssao_intensity = Config.load_setting("display", "ssao_intensity", environment.ssao_intensity)

	environment.glow_enabled      = Config.load_setting("display", "glow",           environment.glow_enabled)
	environment.glow_intensity    = Config.load_setting("display", "glow_intensity", environment.glow_intensity)
	environment.glow_bloom = Config.load_setting("display", "bloom", environment.glow_bloom)
