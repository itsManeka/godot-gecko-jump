class_name SegundaChanceAlvo
extends RefCounted

# Escolha pura da plataforma de reaparicao da Segunda chance (f526 T3), no padrao de ReachableColors: sem arvore
# de cena, recebe tudo por parametro (entradas ja convertidas, posicao da queda, cor do gecko, area jogavel e
# scroll vigente) e nunca altera os argumentos.
#
# Regra unica (Q4 do G1): entre as candidatas visiveis, solidas, com tempo de tela suficiente e com a cor dela na
# linha de cima (predicado de saida, Q6 c), a de menor
# distancia euclidiana ao ponto da queda — de preferencia da cor do gecko; sem nenhuma da cor, a mais proxima de
# qualquer cor, e o resultado informa a cor a assumir (fallback do ADR 0014). Empate exato de distancia: menor y
# (mais alta), depois menor x, depois menor cor — a ordem da lista nunca decide. Sem nenhuma candidata:
# "nenhuma" (Q3: quem chama segue para a derrota padrao, a carga nao se gasta aqui).

# Fisica do pulo lida do Player (nenhum literal novo): a janela minima soma a espera maxima apos o pouso na
# linha de cima — o mesmo par de tempos do preditor de cor (ReachableColors.cor_no_pouso).
const PlayerFisica := preload("res://scenes/Player.gd")


# Indice/entrada da plataforma de reaparicao entre `entradas` (modelo de ReachableColors.entradas_de_plataformas:
# {y, x, cor, desmoronada, desmoronando, pisca_oculta, plataforma, ...}; chave de estado ausente vale falso).
# `gecko` e o ponto da queda; `scroll` e o efetivo (Player.scroll_efetivo()). Devolve:
#   {"indice": <indice em entradas>, "entrada": <a escolhida>, "cor": <cor da escolhida>, "fallback": <bool>}
# "fallback" true = a escolhida nao tem a cor do gecko e "cor" e a cor a assumir. Sem candidata ("nenhuma"):
# {"indice": -1, "entrada": null, "cor": -1, "fallback": false}.
static func escolher(
	entradas: Array, gecko: Vector2, cor_gecko: int, largura: float, altura_visivel: float, scroll: float
) -> Dictionary:
	var candidatas: Array = []
	for i in range(entradas.size()):
		if _e_candidata(entradas[i], entradas, largura, altura_visivel, scroll):
			candidatas.append(i)
	if candidatas.is_empty():
		return _nenhuma()
	var escolhida: int = _mais_proxima(entradas, candidatas, gecko, largura, cor_gecko)
	var fallback: bool = escolhida < 0
	if fallback:
		escolhida = _mais_proxima(entradas, candidatas, gecko, largura, -1)
	var entrada: Dictionary = entradas[escolhida]
	return {"indice": escolhida, "entrada": entrada, "cor": int(entrada["cor"]), "fallback": fallback}


# Resultado sem candidata; dicionario novo a cada chamada.
static func _nenhuma() -> Dictionary:
	return {"indice": -1, "entrada": null, "cor": -1, "fallback": false}


# Candidata: dentro da tela (y em [0, altura_visivel], x em [0, largura]), solida (nem desmoronada, nem
# desmoronando, nem invisivel por piscar), com tempo ate sair da tela >= janela minima e com plataforma da sua
# cor na linha de cima. Scroll 0 = tempo infinito (nunca descarta, sem divisao por zero).
static func _e_candidata(
	e: Dictionary, entradas: Array, largura: float, altura_visivel: float, scroll: float
) -> bool:
	var y: float = float(e["y"])
	var x: float = float(e["x"])
	if y < 0.0 or y > altura_visivel:
		return false
	if x < 0.0 or x > largura:
		return false
	if bool(e.get("desmoronada", false)) or bool(e.get("desmoronando", false)) or bool(e.get("pisca_oculta", false)):
		return false
	if _tempo_ate_sair(y, altura_visivel, scroll) < _janela_minima(scroll):
		return false
	return _tem_cor_na_linha_de_cima(e, entradas, largura, scroll)


# Saida do reaparecimento (Q6 c): a linha de cima da candidata tem plataforma da cor da propria candidata (a cor
# que o gecko tera ali) alcancavel na janela do pulo, pela mesma regra do preditor de cor (ReachableColors). Sem
# isso o gecko reapareceria sobre uma plataforma da qual so se cai.
static func _tem_cor_na_linha_de_cima(e: Dictionary, entradas: Array, largura: float, scroll: float) -> bool:
	var cores: Array = ReachableColors.coletar_cores_linha_acima(
		entradas, float(e["y"]), largura, ReachableColors.tempo_de_pulo(scroll), PlayerFisica.ESPERA_MAXIMA_S
	)
	return cores.has(int(e["cor"]))


# Segundos que a plataforma em y ainda fica na tela descendo `scroll` px/s; scroll 0 = INF (nunca sai).
static func _tempo_ate_sair(y: float, altura_visivel: float, scroll: float) -> float:
	if scroll <= 0.0:
		return INF
	return (altura_visivel - y) / scroll


# Janela minima de vida da plataforma de reaparicao: o gecko precisa pular dela antes que ela saia e ainda
# poder esperar em cima da linha de cima, como no preditor de cor.
static func _janela_minima(scroll: float) -> float:
	return ReachableColors.tempo_de_pulo(scroll) + PlayerFisica.ESPERA_MAXIMA_S


# Distancia euclidiana ao ponto da queda com dx ciente do wrap horizontal (o gecko atravessa a borda):
# min(|dx|, largura - |dx|).
static func _distancia(gecko: Vector2, e: Dictionary, largura: float) -> float:
	var dx_abs: float = absf(float(e["x"]) - gecko.x)
	var dx: float = minf(dx_abs, largura - dx_abs)
	var dy: float = float(e["y"]) - gecko.y
	return sqrt(dx * dx + dy * dy)


# Indice da entrada mais proxima entre `indices`; -1 quando nenhuma passa no filtro de cor (`cor_filtro` < 0 =
# qualquer cor).
static func _mais_proxima(entradas: Array, indices: Array, gecko: Vector2, largura: float, cor_filtro: int) -> int:
	var melhor: int = -1
	for i in indices:
		var e: Dictionary = entradas[i]
		if cor_filtro >= 0 and int(e["cor"]) != cor_filtro:
			continue
		if melhor < 0 or _vence(e, entradas[melhor], gecko, largura):
			melhor = i
	return melhor


# Ordem de preferencia entre candidatas (empate deterministico, documentado): menor distancia, depois menor y
# (mais alta), depois menor x, depois menor cor. Chaves iguais em tudo = mesma posicao e mesma cor (o primeiro
# visto fica, indistinguivel para o chamador).
static func _vence(a: Dictionary, b: Dictionary, gecko: Vector2, largura: float) -> bool:
	var chave_a: Array = [_distancia(gecko, a, largura), float(a["y"]), float(a["x"]), int(a["cor"])]
	var chave_b: Array = [_distancia(gecko, b, largura), float(b["y"]), float(b["x"]), int(b["cor"])]
	return chave_a < chave_b
