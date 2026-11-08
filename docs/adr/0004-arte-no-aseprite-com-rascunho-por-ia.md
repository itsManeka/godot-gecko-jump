# 0004 — Arte no Aseprite compilado do fork pessoal, rascunho por IA

- **Status:** aceito
- **Data:** 2026-11-08
- **Decisores:** itsManeka + Claude

## Contexto

Os assets atuais sao provisorios (um sprite de gecko e um de plataforma, cor via `modulate`). A arte final sera pixel
art. O Aseprite e pago, mas o codigo e publico; a licenca (EULA) permite compilar e modificar **so para uso pessoal**
ou para propor contribuicao, e proibe distribuir binarios.

## Decisao

- Usar o Aseprite compilado do fork `itsManeka/aseprite`, so na maquina do dono. Nunca publicar binario.
- A IA gera **rascunhos** (sprites, animacoes, spritesheets) no tamanho real do jogo; o acabamento e manual no Aseprite.
- Arquivo editavel `.aseprite` + PNG/spritesheet + JSON entram no repo; o original de um sprite e guardado antes de ser
  substituido (`assets/src/_orig/`).
- Cor nunca e a unica pista entre plataformas: forma ou padrao junto (acessibilidade).

## Consequencias

- **Positivas:** ferramenta padrao de pixel art, automatizavel em modo batch (Lua) e por MCP.
- **Negativas / trade-offs:** build C++ local (~9 min) a cada atualizacao do Aseprite.
- **Riscos aceitos:** fork publico de codigo sob EULA restritiva; mitigado por nunca distribuir build.

## Alternativas consideradas

- **LibreSprite (GPL):** livre de verdade, mas parado na base do Aseprite 1.1, sem Lua e sem os MCPs de pixel art.
- **Gerador externo (PixelLab etc.):** rascunho rapido, mas servico pago/externo; nao adotado por ora.
