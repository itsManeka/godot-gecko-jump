class_name PlayArea
extends RefCounted

# Fonte unica da largura jogavel (px logicos): o jogo e so retrato, a largura e sempre 360 (ADR 0002, ADR 0015), mesmo em
# janela larga (barras laterais). Wrap, fantasma, cor do pouso e gerador leem daqui, nunca do viewport.

const LARGURA := 360.0
