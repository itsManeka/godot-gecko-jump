# 0001 — Migrar de Godot 3.6 para Godot 4.7

- **Status:** aceito
- **Data:** 2026-11-08
- **Decisores:** itsManeka + Claude

## Contexto

O prototipo e Godot 3 (`config_version=4`, `KinematicBody2D`, export `HTML5`). O jogo final precisa de export web
e Android atuais, e o ferramental de IA (MCP, documentacao, exemplos) e pensado para Godot 4. O codigo e pequeno:
7 scripts, ~460 linhas.

## Decisao

Migrar para **Godot 4.7.2** (estavel de 2026-08-18) antes de qualquer feature nova, mantendo a mecanica identica.
GDScript passa a ser tipado. O Godot 3.6.3 fica instalado so ate a migracao terminar.

## Consequencias

- **Positivas:** export web/Android atuais; `--headless`, `--import` e `--quit-after` na CLI; GUT 9 e MCP funcionam.
- **Negativas / trade-offs:** conversao manual de cenas e APIs (`CharacterBody2D`, `@onready`, `change_scene_to_file`);
  export web com threads exige cabecalhos COOP/COEP (resolvido exportando sem threads).
- **Riscos aceitos:** pequenas diferencas de fisica entre 3 e 4; o dono confirma jogando que a mecanica ficou igual.

## Alternativas consideradas

- **Ficar no Godot 3.6:** zero migracao, mas export e ferramental desatualizados e sem futuro para Android novo.
