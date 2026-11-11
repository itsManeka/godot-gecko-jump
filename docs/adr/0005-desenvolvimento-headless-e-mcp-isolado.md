# 0005 — Desenvolvimento pela CLI headless; MCPs de jogo so em agentes dedicados

- **Status:** aceito; superado (trecho do gate de "pronto") por [0006](0006-oraculo-de-jogo-em-3-camadas.md)
- **Data:** 2026-11-08
- **Decisores:** itsManeka + Claude

## Contexto

O jogo e desenvolvido com agentes de IA num workspace com outros projetos. Servidores MCP carregados na sessao
principal custam contexto em toda conversa, inclusive nas de outros projetos. O Godot roda inteiro pela CLI
(importar, checar script, rodar, testar, exportar).

## Decisao

- Fluxo padrao 100% pela CLI headless; o oraculo e `node .verify.mjs <wave>` (import + checagem + GUT + execucao,
  varrendo o stderr porque o Godot nem sempre muda o exit code).
- MCP do Godot (`@coding-solo/godot-mcp`) e do Aseprite (`@letsagents/aseprite-mcp`) so dentro de agentes dedicados
  (`godot-runtime`, `pixel-artist`), declarados inline no agente: sobem quando o agente roda e nao entram na sessao
  principal.
- Gate de "pronto" de mudanca jogavel: o dono joga.

## Consequencias

- **Positivas:** custo de contexto zero fora das tarefas do jogo; verificacao reproduzivel por qualquer chat limpo.
- **Negativas / trade-offs:** problemas so visiveis com janela (render, input) dependem do agente `godot-runtime` ou do
  dono jogando.
- **Riscos aceitos:** o `.verify.mjs` sem input nao exercita gameplay; coberto pelos testes GUT (#7).

## Alternativas consideradas

- **MCP do Godot na sessao principal:** mais conveniente, mas carrega ferramentas em toda conversa do workspace.
- **Editor aberto:** feedback visual imediato, mas nao automatizavel.
