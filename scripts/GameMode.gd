class_name GameMode
extends RefCounted

# Definicao de modo de jogo (infraestrutura de modos, sem cena): dados de exibicao + regra do hook.
# Ids estaveis em texto minusculo sem acento: o id e a chave do recorde do modo (BestScoreStore por id),
# nunca o rotulo ou o nome mutaveis — renomear rotulo nao perde recorde.

var id: StringName
# Rotulo curto do seletor (botao "Modo: <rotulo>" do menu e marca do carrossel).
var rotulo: String
# Nome completo exibido na tela de modos.
var nome: String
# Descricao exibida na tela de modos.
var descricao: String
# Regra consultada pela Stage durante a partida (derrota, fim, pontuacao, recorde, power-ups).
var regra: GameModeRule


func _init(id_: StringName, rotulo_: String, nome_: String, descricao_: String, regra_: GameModeRule) -> void:
	id = id_
	rotulo = rotulo_
	nome = nome_
	descricao = descricao_
	regra = regra_
