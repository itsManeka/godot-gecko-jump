# 🦎 Gecko Jump

<div align="center">

![Godot Engine](https://img.shields.io/badge/Godot-4.7-blue?logo=godot-engine&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-PC-orange.svg)

*Um jogo de plataforma colorido e dinâmico desenvolvido em Godot Engine!*

[🎮 Como Jogar](#-como-jogar) • [📱 Download](#-download) • [🛠️ Tecnologias](#️-tecnologias-utilizadas) • [🌍 English](#-english-version)

</div>

## 📖 Descrição

**Gecko Jump** é um jogo de plataforma onde você controla um camaleão confuso que muda de cor! 

### 🎯 Objetivo
- **Pular apenas nas plataformas da mesma cor** que o Gecko
- **Ganhar pontos** a cada plataforma nova que tocar
- **Mudar de cor automaticamente** após cada pulo bem-sucedido
- **Sobreviver** o máximo de tempo possível descendo pelas plataformas
- **Bater o recorde**: a maior pontuação fica salva e continua lá quando você abre o jogo de novo

## 🎮 Controles

| Ação | Teclas |
|------|--------|
| **Pular** | `Espaço`, `W` ou `↑` |
| **Mover para Esquerda** | `A` ou `←` |
| **Mover para Direita** | `D` ou `→` |

## 🚀 Como Jogar

1. Pressione qualquer tecla de pulo para começar
2. Use as setas ou WASD para mover o Gecko
3. Pule apenas em plataformas da mesma cor que o Gecko
4. Evite cair ou tocar plataformas de cores diferentes
5. Tente alcançar a maior pontuação possível!

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
- **Resolução:** 180x320 (modo retrato)
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

⚠️ **Aviso:** Este jogo foi desenvolvido para PC e não está otimizado para dispositivos móveis.

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

Na pagina do PR, abra o run do `CI` e baixe o artefato `export-web` na secao *Artifacts* (guardado por 7 dias).
Descompacte e sirva a pasta por um servidor estatico, como na secao Download.

### Rodar o oraculo localmente

Aponte a variavel `GODOT_PATH` para o executavel do Godot 4.7.2 e rode na raiz do projeto:

```
GODOT_PATH=/caminho/para/Godot_v4.7.2-stable_linux.x86_64 node .verify.mjs ci
```

No Windows, defina `GODOT_PATH` com o caminho do executavel antes de rodar o mesmo comando.

### Versao do Godot no CI

O Godot 4.7.2 oficial e baixado do release `4.7.2-stable` do repositorio `godotengine/godot` pela action local
`.github/actions/setup-godot/action.yml`. O arquivo baixado e conferido por soma SHA-512 fixada no proprio arquivo
antes do uso, e o binario e os export templates web ficam em cache (a chave muda com a versao e a soma). A soma
do binario e conferida em todo run, inclusive quando ele vem do cache. O cache de um PR so serve ao proprio PR: o
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
- **Change color automatically** after each successful jump
- **Survive** as long as possible while descending through the platforms
- **Beat your best score**: it is saved and still there the next time you open the game

### 🎮 Controls

| Action | Keys |
|--------|------|
| **Jump** | `Space`, `W` or `↑` |
| **Move Left** | `A` or `←` |
| **Move Right** | `D` or `→` |

### 🚀 How to Play

1. Press any jump key to start
2. Use arrows or WASD to move the Gecko
3. Jump only on platforms of the same color as the Gecko
4. Avoid falling or touching platforms of different colors
5. Try to achieve the highest score possible!

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

### 📱 Compatibility

⚠️ **Warning:** This game was developed for PC and is not optimized for mobile devices.

**Requirements:**
- Godot Engine 4.7.2
- Operating System: Windows, Linux, macOS
