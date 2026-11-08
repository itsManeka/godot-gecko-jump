# Gecko Jump — Briefing para o Claude Code

Nov 8, 2026 · @Emanuel

## Contexto e objetivo

O Emanuel (dev em Criciúma/SC) quer retomar o Gecko Jump, um protótipo em Godot feito para a game jam #1JAM Chroma, e publicar uma versão final. Este documento resume a análise do repositório e define por onde começar.

- **Repositório:** github.com/itsManeka/godot-gecko-jump (público, último commit em 30/09/2025).
- **Onde você trabalha:** no dev workspace do Emanuel, na máquina dele.
- **Entrega esperada:** jogo final publicado, primeiro na web (itch.io); Android só se ele confirmar.
- **Quem decide:** as decisões da seção "Decisões a confirmar" são do Emanuel. Pergunte antes de assumir.

## Estado atual do repositório

O projeto é um jogo de plataforma vertical em Godot 3 (`config_version=4`, `KinematicBody2D`, pasta `.import/`), tela 180×320 em retrato, com cerca de 460 linhas de GDScript. Um gecko pula entre plataformas de 4 cores e só pisa nas da mesma cor dele. Depois de cada pouso ele troca de cor aleatoriamente e ganha 1 ponto; o scroll é infinito.

| Arquivo | Papel |
| --- | --- |
| `scenes/Stage.gd` (64 linhas) | Fluxo do jogo, pontuação, reinício por `change_scene` |
| `scenes/Player.gd` (123) | Movimento, pulo, animações, troca de cor ao pousar |
| `scenes/Platform.gd` (48) | Colisão ligada só quando a cor bate com a do jogador |
| `scenes/RuningPlatforms.gd` (86) | Gerador de plataformas (estáticas, esquerda, direita); nome com erro de digitação |
| `scenes/ScrollLevel.gd` (43) | Scroll de 20 px/s e criação de geradores |
| `scripts/Global.gd` (63) | Autoload: lista de plataformas, estado, recorde |
| `scripts/Enums.gd` (34) | Cores (#f6db61, #79cf5a, #5987e9, #ec4848) e tipos de plataforma |

**Assets:** 3 imagens (`Gecko.png` 64×96, `GeckoPlataforma.png` 64×16, `icon.png` 32×32), 2 sons (`jump.wav`, `lose.wav`) e a fonte `alterebro-pixel-font.ttf`. As cores vêm de `modulate` sobre um sprite único. O preset de export atual é só HTML5.

**Pontos fracos que impedem um jogo final:**

- O recorde não é salvo e zera ao fechar o jogo.
- A dificuldade é constante (velocidade 60, scroll 20).
- Não há som de pouso ou de ponto, nem música.
- Só há controle por teclado; o README diz que não é otimizado para celular.
- Faltam pausa, opções e tutorial.
- A lista `platforms` do `Global` pode guardar referências a plataformas já liberadas.
- A cor inicial do gecko não é garantida como compatível com as plataformas de partida.

## Decisões a confirmar com o Emanuel

Pergunte estas cinco antes de mexer no código. A recomendação de cada uma vem entre parênteses.

- [ ] Migrar de Godot 3 para Godot 4? (recomendado: sim, são só 7 scripts e o ferramental atual é pensado para Godot 4)
- [ ] Plataformas de lançamento: web/itch.io, Android ou ambas? (recomendado: web primeiro, Android depois)
- [ ] Manter o formato retrato 180×320? (recomendado: sim, é o que pede toque no celular)
- [ ] Escopo de gameplay: manter só a mecânica de cores ou somar power-ups e modos? (recomendado: manter e polir)
- [ ] Arte: redesenhar tudo em pixel art com Aseprite, ele já tem licença? (recomendado: sim, com apoio de IA para rascunhos)

## Setup de ferramentas

O Godot roda inteiro pela linha de comando, então você consegue importar, testar e exportar sem abrir o editor. Comece pelo `godot --headless` e só acrescente MCP se faltar contexto do projeto. Confira cada comando na documentação do projeto antes de instalar.

| Ferramenta | Para que serve | Como instalar |
| --- | --- | --- |
| Godot headless | Importar assets, rodar e exportar sem GUI | Instalar o Godot 4 e colocar no PATH (ou `GODOT_PATH`) |
| [godot-mcp (Coding-Solo)](https://github.com/Coding-Solo/godot-mcp) | Criar cenas e nós, rodar o projeto e ler erros | `claude mcp add godot -- npx @coding-solo/godot-mcp` (precisa de Node 18+) |
| [pixel-plugin](https://github.com/willibrandon/pixel-plugin) | Criar e animar pixel art no Aseprite por linguagem natural | `/plugin marketplace add willibrandon/pixel-plugin`, depois `/pixel-setup` (precisa de Aseprite 1.3.0+) |
| [aseprite-mcp (letsagents)](https://github.com/letsagents/aseprite-mcp) | Alternativa com 76 ferramentas: camadas, paletas, spritesheet | `npm install -g @letsagents/aseprite-mcp` |
| PixelLab | Rascunhos de sprites e animações (serviço externo) | Conta no site; o Emanuel decide se usa |

**Regra para pixel art:** a IA gera o rascunho e o acabamento é manual no Aseprite. Teste os sprites no tamanho real do jogo (180×320), não ampliados.

**Fontes:** [Headless com Claude Code e Godot](https://thebrandonwu.substack.com/p/building-a-visual-novel-with-claude), [Godot e agentes de IA](https://dev.to/abagames/godot-is-well-suited-for-game-development-with-ai-coding-agents-2lcm), [Servidores MCP para Godot em 2026](https://www.summerengine.com/blog/best-godot-mcp-server), [Ferramentas de pixel art com IA](https://freegamesprites.com/news/ai-pixel-art-generation-2026-tools-and-workflows).

## Roadmap em fases

Seis fases em ordem. Cada uma termina num critério verificável e só então a próxima começa.

1. **Preparação.** Criar o `CLAUDE.md` do projeto, um `.gitignore` para arquivos gerados pelo Godot e uma branch de trabalho. Rodar o jogo como está para ter uma base. *Pronto quando:* o jogo abre e uma partida completa funciona.
2. **Migração para Godot 4.** Converter cenas e scripts (`KinematicBody2D` vira `CharacterBody2D`, `onready` vira `@onready` e assim por diante). *Pronto quando:* a mecânica é igual à original e o export web roda pelo terminal.
3. **Correções e base sólida.** Salvar o recorde em `user://`, limpar a lista `platforms`, garantir cor inicial válida e renomear `RuningPlatforms`. *Pronto quando:* o recorde sobrevive a fechar o jogo e não há erros no console.
4. **Gameplay e polimento.** Dificuldade progressiva, pausa, tutorial curto, controles de toque e efeitos de game feel. *Pronto quando:* uma pessoa de fora joga 5 minutos sem pedir explicação.
5. **Arte e áudio.** Gecko com animações de parado, corrida, pulo, queda e derrota; plataformas, fundo e interface em pixel art; sons de pouso e ponto; música. *Pronto quando:* nenhum asset provisório resta no jogo.
6. **Publicação.** Export web, página no itch.io com capturas, README atualizado e, se confirmado, build Android. *Pronto quando:* o jogo está jogável por um link público.

## Regras de trabalho e primeira tarefa

**Regras:**

- Trabalhe numa branch e faça commits pequenos, um por mudança lógica.
- Guarde cópia dos sprites originais antes de substituí-los.
- Valide mudanças rodando o Godot pela linha de comando e, quando houver MCP, lendo os erros reais de execução.
- Não assuma as decisões da seção acima; pergunte ao Emanuel.
- Ao fim de cada fase, resuma o que mudou e o critério de "pronto" atendido.

**Primeira tarefa** (cole como prompt):

```markdown
Leia este briefing inteiro. Depois:
1. Clone/abra godot-gecko-jump no meu workspace e confirme que o estado bate com a seção "Estado atual".
2. Me faça as cinco perguntas da seção "Decisões a confirmar", uma de cada vez.
3. Com as respostas, crie o CLAUDE.md do projeto (versão do Godot, comandos headless, convenções de GDScript, estrutura de pastas).
4. Execute a Fase 1 e pare para eu revisar antes de começar a migração.
```
