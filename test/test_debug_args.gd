extends GutTest

## Parser puro dos args de usuario (DebugArgs.find/fonte). Sem ambiente, sem arvore de cena.


func test_valor_de_seed_vem_do_argumento() -> void:
	assert_eq(DebugArgs.find(PackedStringArray(["--seed=42"]), "seed"), "42", "--seed=42 devolve o valor 42")


func test_flag_sem_valor_devolve_string_vazia() -> void:
	var achado: Variant = DebugArgs.find(PackedStringArray(["--x"]), "x")
	assert_true(achado != null, "flag presente nao e ausente")
	assert_eq(achado, "", "flag sem valor vira string vazia, como ?x no web")


func test_ausente_e_args_vazio_devolvem_null() -> void:
	assert_true(DebugArgs.find(PackedStringArray(["--a=1"]), "seed") == null, "nome ausente devolve null")
	assert_true(DebugArgs.find(PackedStringArray(), "seed") == null, "args vazio devolve null")


func test_nome_exato_nao_casa_por_prefixo() -> void:
	assert_true(DebugArgs.find(PackedStringArray(["--seedx=1", "--seed2=1"]), "seed") == null, "prefixo comum nao casa")
	assert_eq(DebugArgs.find(PackedStringArray(["--seedx=1", "--seed=7"]), "seed"), "7", "o nome exato ainda casa depois do prefixo")


func test_valor_com_igual_interno_preserva_o_resto() -> void:
	assert_eq(DebugArgs.find(PackedStringArray(["--a=b=c"]), "a"), "b=c", "so o primeiro = separa o nome do valor")


func test_repeticao_primeiro_vence() -> void:
	assert_eq(DebugArgs.find(PackedStringArray(["--seed=1", "--seed=2"]), "seed"), "1", "a primeira ocorrencia vale")


func test_argumento_sem_dois_tracos_e_ignorado() -> void:
	assert_true(DebugArgs.find(PackedStringArray(["seed=42"]), "seed") == null, "sem -- nao e argumento de usuario")
	assert_true(DebugArgs.find(PackedStringArray(["-seed=42"]), "seed") == null, "um traco so tambem nao")


func test_release_nativo_com_arg_devolve_null() -> void:
	assert_true(DebugArgs.fonte(false, false, PackedStringArray(["--seed=42"]), "seed") == null, "release ignora o arg mesmo valido")


func test_web_nao_le_args_de_usuario() -> void:
	assert_true(DebugArgs.fonte(true, true, PackedStringArray(["--seed=42"]), "seed") == null, "o ramo web nao le args de usuario")


func test_seed_read_raw_sem_args_devolve_null() -> void:
	assert_true(SeedSource.read_raw() == null, "runner GUT sem --seed devolve null")


func test_semderrota_read_raw_sem_args_devolve_null() -> void:
	assert_true(ModoSemDerrota.read_raw() == null, "runner GUT sem --semderrota devolve null")


func test_dica_read_raw_sem_args_devolve_null() -> void:
	assert_true(ModoDicaToque.read_raw() == null, "runner GUT sem --dica devolve null")


func test_tutorial_read_raw_sem_args_devolve_null() -> void:
	assert_true(ModoTutorialVisto.read_raw() == null, "runner GUT sem --tutorial devolve null")


func test_progresso_read_raw_sem_args_devolve_null() -> void:
	assert_true(ModoProgressoInicial.read_raw() == null, "runner GUT sem --progresso devolve null")


func test_nativo_debug_le_o_arg_e_sem_arg_null() -> void:
	assert_eq(DebugArgs.fonte(false, true, PackedStringArray(["--seed=42"]), "seed"), "42", "nativo debug com arg devolve o valor")
	assert_true(DebugArgs.fonte(false, true, PackedStringArray(), "seed") == null, "nativo debug sem arg devolve null")
