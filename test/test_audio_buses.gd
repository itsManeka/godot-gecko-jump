extends GutTest

const PLAYER_CENA := "res://scenes/Player.tscn"
const STAGE_CENA := "res://scenes/Stage.tscn"


func test_c177_buses_music_e_sfx_existem_com_saida_master() -> void:
	var idx_music: int = AudioServer.get_bus_index("Music")
	var idx_sfx: int = AudioServer.get_bus_index("SFX")
	assert_gte(idx_music, 0, "bus Music ausente do AudioServer")
	assert_gte(idx_sfx, 0, "bus SFX ausente do AudioServer")
	assert_eq(AudioServer.get_bus_send(idx_music), &"Master", "Music deve sair em Master")
	assert_eq(AudioServer.get_bus_send(idx_sfx), &"Master", "SFX deve sair em Master")


func test_c178_jump_e_lose_audio_rotulados_sfx() -> void:
	var player: Node = add_child_autofree(load(PLAYER_CENA).instantiate())
	var stage: Node = add_child_autofree(load(STAGE_CENA).instantiate())
	var jump_audio: AudioStreamPlayer = player.get_node("JumpAudio")
	var lose_audio: AudioStreamPlayer = stage.get_node("LoseAudio")
	assert_eq(jump_audio.bus, &"SFX", "JumpAudio deve tocar no bus SFX")
	assert_eq(lose_audio.bus, &"SFX", "LoseAudio deve tocar no bus SFX")
