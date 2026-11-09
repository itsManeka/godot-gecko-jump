extends GutTest

# Smoke da infra GUT: prova que o runner headless descobre e executa testes.

func test_gut_executa_teste() -> void:
	assert_eq(1 + 1, 2, "GUT deve executar e avaliar asserts")
