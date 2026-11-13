# 🦎 Gecko Jump

<div align="center">

![Godot Engine](https://img.shields.io/badge/Godot-4.7-blue?logo=godot-engine&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-PC-orange.svg)

_Um jogo de plataforma colorido e dinâmico desenvolvido em Godot Engine!_

[🎮 Como Jogar](#-como-jogar) • [📱 Download](#-download) • [🛠️ Tecnologias](#️-tecnologias-utilizadas) • [🌍 English](#-english-version)

</div>

## 📖 Descrição

**Gecko Jump** é um jogo de plataforma onde você controla um camaleão confuso que muda de cor!

### 🎯 Objetivo

- **Pular apenas nas plataformas da mesma cor** que o Gecko
- **Ganhar pontos** a cada plataforma nova que tocar
- **Mudar de cor automaticamente** após cada pulo bem-sucedido — a cor nova sempre existe numa plataforma da linha de cima
- **Sobreviver** o máximo de tempo possível descendo pelas plataformas
- **Bater o recorde**: a maior pontuação fica salva e continua lá quando você abre o jogo de novo

## 🎮 Controles

| Ação                    | Teclas                           | Toque (um polegar)                                                  |
| ----------------------- | -------------------------------- | ------------------------------------------------------------------- |
| **Pular**               | `Espaço`, `W` ou `↑`             | Toque rápido numa metade da tela: pulo na diagonal para aquele lado |
| **Mover para Esquerda** | `A` ou `←`                       | Segure na metade esquerda                                           |
| **Mover para Direita**  | `D` ou `→`                       | Segure na metade direita                                            |
| **Pausar / Continuar**  | `Esc` ou `P` (start no controle) | Botão de pausa no canto superior esquerdo                           |

No celular, uma dica discreta mostra as duas metades na primeira partida e some sozinha.

A partida também pausa sozinha quando a janela ou a aba perde o foco, ou quando o app vai para segundo plano. Para
voltar, use **Continuar**, `Esc` ou `P`. No desktop, o botão de pausa e o menu de pausa também aceitam clique do mouse.

**Opções** (botão no menu inicial, entre Play e Last, ou no menu de pausa): volume da música e dos efeitos sonoros, de
0 (mudo) a 100%, por arrasto ou com `←`/`→`. Os volumes ficam salvos e continuam valendo quando você abre o jogo de novo.
No menu, `↓` leva o foco até **Opções** e `Enter` abre a tela.

Na primeira partida, um cartão mostra os controles e some no primeiro pouso (ou em **Pular**). Para vê-lo de novo,
use **Opções > Ver tutorial**.

## 🚀 Como Jogar

1. Pressione qualquer tecla de pulo (ou toque na tela) para começar
2. Use as setas ou WASD para mover o Gecko; ao sair por uma lateral da tela, ele reaparece pela outra
3. Pule apenas em plataformas da mesma cor que o Gecko
4. Evite cair ou tocar plataformas de cores diferentes
5. Quanto mais você pontua e mais tempo sobrevive, mais rápido a tela sobe e as plataformas andam; cada partida recomeça no ritmo inicial
6. Tente alcançar a maior pontuação possível!

## 📱 Download

> 🚧 **Em desenvolvimento** - O jogo ainda não possui release oficial.

Para jogar agora:

1. Clone este repositório
2. Abra o projeto no Godot Engine 4.7.2
3. Execute a cena principal `scenes/Stage.tscn`

Para gerar a versão web (sem threads):

1. Instale os export templates do Godot 4.7.2 (`Web`, sem threads)
2. Na raiz do projeto, rode o export substituindo `<godot>` pelo executável do Godot 4.7.2:
   ```
   <godot> --headless --path . --export-release "Web" export/web/index.html
   ```
3. Sirva a pasta `export/web/` por um servidor estático local, por exemplo `npx serve export/web`. Não abra o `index.html` direto pelo navegador (`file://`): o carregamento do `.wasm`/`.pck` falha.

## 🛠️ Tecnologias Utilizadas

- **Engine:** Godot Engine 4.7.2
- **Linguagem:** GDScript
- **Resolução:** retrato, 180 px de largura e altura que acompanha a tela do aparelho (mínimo 320), com escala inteira para manter o pixel quadrado; em janela mais larga (desktop, navegador), a área de jogo fica centralizada com barras laterais
- **Áudio:** Efeitos sonoros integrados

## 📁 Estrutura do Projeto

```
godot-gecko-jump/
├── assets/           # Sprites e recursos visuais
├── scenes/          # Cenas do Godot (.tscn) e scripts (.gd)
├── scripts/         # Scripts globais e classes de logica (Global.gd, Enums.gd, ScoreKeeper.gd, BestScoreStore.gd, PlatformTypePicker.gd)
├── test/            # Testes automatizados (GUT)
├── addons/          # Addon GUT v9.7.1 (framework de testes; idêntico à tag v9.7.1, commit aeb5d4f3f7f0a6c9b5e178876d6c99b791fda605)
├── sounds/          # Efeitos sonoros
├── fonts/           # Fontes personalizadas
└── project.godot    # Arquivo de projeto do Godot
```

## 📱 Compatibilidade

A tela é pensada para celular (retrato, 180 px de largura) e o jogo aceita toque com um polegar, além de teclado.

**Requisitos:**

- Godot Engine 4.7.2
- Sistema operacional: Windows, Linux, macOS

## 🔧 Desenvolvimento e CI

Pull requests para `main` e pushes em `main` que mudem arquivos fora de Markdown e de `docs/` rodam o workflow
[`CI`](.github/workflows/ci.yml), com tres jobs:

- **verify**: roda o oraculo `node .verify.mjs ci` (import, compilacao dos scripts, testes GUT e execucao de 10 s) com o Godot 4.7.2.
- **export-web**: exporta o preset `Web` (sem threads) para `export/web/` e confere que `index.html`, um `.wasm` e um `.pck` existem e nao estao vazios.
- **CI**: agregador; falha se qualquer um dos dois jobs anteriores falhar.

### Baixar o build web de um PR

Na pagina do PR, abra o run do `CI` e baixe o artefato `export-web` na secao _Artifacts_ (guardado por 7 dias).
Descompacte e sirva a pasta por um servidor estatico, como na secao Download.

### Rodar o oraculo localmente

Aponte a variavel `GODOT_PATH` para o executavel do Godot 4.7.2 e rode na raiz do projeto:

```
GODOT_PATH=/caminho/para/Godot_v4.7.2-stable_linux.x86_64 node .verify.mjs ci
```

No Windows, defina `GODOT_PATH` com o caminho do executavel antes de rodar o mesmo comando.

### Smoke do build web

O roteiro `test/smoke/gecko.smoke.json` joga o export web num navegador headless (iniciar, pular, morrer, reiniciar,
pular) e acusa erro de pagina, recurso faltando e tela congelada. Rode-o sobre a pasta do export (`export/web/`) com o
`game-smoke.mjs` do dev-workspace: `node <dev-workspace>/.claude/scripts/game-smoke.mjs export/web --spec=test/smoke/gecko.smoke.json --out=<pasta dos prints>`.

Os roteiros conferem o estado da partida, nao so a tela. Isso so funciona no export web de **debug**; o build de
release (o publicado) ignora os parametros abaixo e nao publica nada:

- `?seed=<numero>` no `path` do roteiro fixa o sorteio de cores e plataformas. Todo roteiro leva uma seed.
- `?semderrota=1` liga o modo sem derrota (plataformas na cor inicial e paradas; a queda pela borda ainda encerra a
  partida), usado pelos roteiros `retrato-pontua-1080x2772.smoke.json` (conferir que o gecko pontua),
  `estagio.smoke.json` (conferir que a dificuldade sobe) e pelos roteiros longos (`gecko` e os `retrato-*` de cada
  tamanho), para o gecko nao morrer por cor errada entre os pulos (#39).
- `?progresso=<0 a 1>` comeca a partida no ponto da curva de dificuldade indicado (valor invalido vale 0), usado pelo
  roteiro `estagio.smoke.json`.
- `?dica=1` força a dica de toque sem aparelho de toque, usado pelo roteiro `dica-toque.smoke.json`. O runner só
  clica com mouse, então tap e segurar por tempo não são jogados pelos roteiros (`toque.smoke.json` confere o início por clique).
- `?tutorial=visto` marca o tutorial da primeira partida como já visto (sem gravar nada), para o cartão não cobrir a
  tela. Todo roteiro leva o parâmetro, menos `tutorial.smoke.json`, que joga a primeira partida com o armazenamento limpo.
- O jogo publica `window.__GAME_STATE__` com `score`, `best`, `state` (`menu`, `playing` ou `lost`), `player.alive` e
  `dificuldade.estagio` (inteiro, 0 no inicio da partida; republicado quando o estagio muda).
  O passo `expect` do roteiro le esses campos, por exemplo `{"expect": {"state": "playing"}, "timeout_ms": 3000}`.
  O roteiro `estagio.smoke.json` prova que o estagio sobe de 0 para 1 ou mais durante a partida.

Os roteiros longos nao exigem pontuacao: conferem `playing` depois do Play e que a partida deixou de estar em
`playing` depois da queda pela borda. Antes de cada rajada de pulo, o roteiro tambem espera `playing`, para que uma
derrota anterior apareca como falha de estado e nao como tela congelada. Pontuacao so e conferida no roteiro
`retrato-pontua-1080x2772`.
Pela mesma razao, uma rajada `"moving": true` que o runner reprova por tela congelada (com `freeze_shots` prints ou
mais, 4 por padrao) tem de terminar ate 1500 ms depois do Play (`wait` + `(shots-1)*every`): a recarga depois de uma
derrota so vem ~2,3 s depois do Play, e menu parado dentro da rajada vira `canvas congelado`. O teste
`test/test_smoke_roteiros.gd` confere esse orcamento.

### Versao do Godot no CI

O Godot oficial, na versao fixada em `GODOT_VERSION`, e baixado do release `<versao>-stable` do repositorio
`godotengine/godot` pela action local `.github/actions/setup-godot/action.yml`. O arquivo baixado e conferido por
soma SHA-512 fixada no proprio arquivo antes do uso, e o binario e os export templates web ficam em cache (a chave
muda com a versao e a soma). A soma do binario e conferida em todo run, inclusive quando ele vem do cache; a dos
templates, so no download, pois o cache deles so e gravado depois dessa conferencia. O cache de um PR so serve ao proprio PR: o
primeiro run de cada PR baixa o Godot, e depois do CI verde na `main` o cache dela passa a servir os PRs.
As actions externas sao fixadas por SHA de commit e atualizadas mensalmente pelo Dependabot.

Para trocar a versao do Godot, atualize em `.github/actions/setup-godot/action.yml` a variavel `GODOT_VERSION` e
as duas somas SHA-512 (conferidas no `SHA512-SUMS.txt` do release); nomes de arquivo, URL, diretorios e chaves de
cache derivam delas.

Origem e decisoes do CI: issue [#28](https://github.com/itsManeka/godot-gecko-jump/issues/28).

## 🗺️ Roadmap

O jogo está sendo levado da versão da game jam para uma versão final para celular (Android) e web (itch.io).
Plano e fases: [`docs/planejamento-implementacao.md`](docs/planejamento-implementacao.md). Decisões:
[`docs/adr/`](docs/adr/README.md). Bugs e próximos passos: [issues](https://github.com/itsManeka/godot-gecko-jump/issues).

## 🤝 Contribuindo

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'Add some AmazingFeature'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 🏆 Créditos

Jogo desenvolvido para a **[#1JAM Chroma](https://itch.io/jam/1jam-chroma)** - uma game jam focada em mecânicas baseadas em cores.

### 👨‍💻 Autor

**Emanuel Ozorio**

- GitHub: [@itsManeka](https://github.com/itsManeka)
- Email: [emanuel.ozoriodias@gmail.com](mailto:emanuel.ozoriodias@gmail.com)

---

## 🌍 English Version

**Gecko Jump** is a colorful and dynamic platform game developed in Godot Engine!

### 📖 Description

**Gecko Jump** is a platform game where you control a confused chameleon that changes colors!

#### 🎯 Objective

- **Jump only on platforms of the same color** as the Gecko
- **Earn points** for each new platform you touch
- **Change color automatically** after each successful jump — the new color is always on a platform in the row above
- **Survive** as long as possible while descending through the platforms
- **Beat your best score**: it is saved and still there the next time you open the game

### 🎮 Controls

| Action             | Keys                              | Touch (one thumb)                                               |
| ------------------ | --------------------------------- | --------------------------------------------------------------- |
| **Jump**           | `Space`, `W` or `↑`               | Quick tap on one half of the screen: diagonal jump to that side |
| **Move Left**      | `A` or `←`                        | Hold on the left half                                           |
| **Move Right**     | `D` or `→`                        | Hold on the right half                                          |
| **Pause / Resume** | `Esc` or `P` (start on a gamepad) | Pause button in the top-left corner                             |

On phones, a subtle hint shows both halves in the first match and fades out on its own.

The match also pauses on its own when the window or tab loses focus, or when the app goes to the background. To resume,
use **Continuar**, `Esc` or `P`. On desktop, the pause button and the pause menu also accept mouse clicks.

**Options** (button on the start menu, between Play and Last, or in the pause menu): music and sound effects volume,
from 0 (muted) to 100%, by dragging or with `←`/`→`. Volumes are saved and still apply the next time you open the game.
On the menu, `↓` moves the focus to **Opcoes** and `Enter` opens the screen.

In the first match, a card shows the controls and fades out on the first landing (or on **Pular**). To see it again,
use **Opcoes > Ver tutorial**.

### 🚀 How to Play

1. Press any jump key (or tap the screen) to start
2. Use arrows or WASD to move the Gecko; leaving through one side of the screen brings it back on the other
3. Jump only on platforms of the same color as the Gecko
4. Avoid falling or touching platforms of different colors
5. The more you score and the longer you survive, the faster the screen climbs and the platforms move; every run starts over at the initial pace
6. Try to achieve the highest score possible!

### 📱 Download

> 🚧 **In development** - The game doesn't have an official release yet.

To play now:

1. Clone this repository
2. Open the project in Godot Engine 4.7.2
3. Run the main scene `scenes/Stage.tscn`

To build the web version (no threads):

1. Install the Godot 4.7.2 export templates (`Web`, no threads)
2. From the project root, run the export replacing `<godot>` with the Godot 4.7.2 executable:
   ```
   <godot> --headless --path . --export-release "Web" export/web/index.html
   ```
3. Serve the `export/web/` folder with a local static server, for example `npx serve export/web`. Do not open `index.html` directly in the browser (`file://`): loading the `.wasm`/`.pck` fails.

### Web build smoke

The `test/smoke/gecko.smoke.json` script plays the web export in a headless browser (start, jump, die, restart,
jump) and reports page errors, missing resources and a frozen screen. Run it against the export folder (`export/web/`)
with the dev-workspace `game-smoke.mjs`: `node <dev-workspace>/.claude/scripts/game-smoke.mjs export/web --spec=test/smoke/gecko.smoke.json --out=<screenshots folder>`.

The scripts check the match state, not only the screen. This only works on the **debug** web export; the release
build (the published one) ignores the parameters below and publishes nothing:

- `?seed=<number>` in the script `path` fixes the color and platform draw. Every script carries a seed.
- `?semderrota=1` turns on the no-defeat mode (platforms in the initial color and standing still; falling off the
  edge still ends the match), used by the `retrato-pontua-1080x2772.smoke.json` script (to check that the gecko
  scores), the `estagio.smoke.json` script (to check that the difficulty rises) and the long scripts (`gecko` and the
  `retrato-*` of each size), so the gecko does not die by a wrong color between jumps (#39).
- `?progresso=<0 to 1>` starts the match at that point of the difficulty curve (an invalid value means 0), used by the
  `estagio.smoke.json` script.
- `?dica=1` forces the touch hint without a touch device, used by the `dica-toque.smoke.json` script. The runner only
  clicks with a mouse, so tap and hold by time are not played by the scripts (`toque.smoke.json` checks the start with a click).
- `?tutorial=visto` marks the first-match tutorial as already seen (without saving anything), so the card does not
  cover the screen. Every script carries it, except `tutorial.smoke.json`, which plays the first match with clean storage.
- The game publishes `window.__GAME_STATE__` with `score`, `best`, `state` (`menu`, `playing` or `lost`),
  `player.alive` and `dificuldade.estagio` (an integer, 0 at the start of the match; republished when the stage changes).
  The script `expect` step reads those fields, for example `{"expect": {"state": "playing"}, "timeout_ms": 3000}`.
  The `estagio.smoke.json` script checks that the stage rises from 0 to 1 or more during the match.

The long scripts do not require a score: they check `playing` after Play and that the match left `playing` after
the fall off the edge. Before each jump burst, the long scripts also wait for `playing`, so an earlier defeat shows up
as a state failure and not as a frozen screen. Scoring is only checked in the `retrato-pontua-1080x2772` script.
For the same reason, a `"moving": true` burst that the runner fails as a frozen screen (`freeze_shots` screenshots or
more, 4 by default) must end within 1500 ms of Play (`wait` + `(shots-1)*every`): the reload after a defeat only comes
~2.3 s after Play, and a still menu inside the burst becomes `canvas congelado`. The
`test/test_smoke_roteiros.gd` test checks this budget.

### 📱 Compatibility

The screen is designed for phones (portrait, 180 px wide) and the game accepts one-thumb touch as well as a keyboard.

**Requirements:**

- Godot Engine 4.7.2
- Operating System: Windows, Linux, macOS
