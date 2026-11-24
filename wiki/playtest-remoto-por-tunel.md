# Subir o jogo por um túnel (playtest no celular fora de casa)

Põe o export web do Gecko Jump numa URL HTTPS temporária para jogar no celular sem deploy, e derruba depois.
Usa `cloudflared` em modo *quick tunnel* (sem conta). Quem automatiza o passo a passo é o
`.claude/scripts/playtest-remoto.mjs` do workspace.

> **A URL é pública enquanto o túnel estiver no ar.** Qualquer pessoa com o link joga. Suba só quando for usar e
> derrube ao terminar.

## Pré-requisitos

- Godot 4 com os export templates Web instalados e o preset `Web` em `export_presets.cfg` (já existe).
- `cloudflared` em `D:/Dev/.tools/cloudflared/cloudflared.exe` (caminho em `tools.cloudflared` do eco `game-gecko`
  no `.claude/workspace-config.json`). Outro binário: `--cloudflared=<bin>` ou env `CLAUDE_CLOUDFLARED_BIN`.
- Executável do Godot em `tools.godot` do mesmo bloco (ou `--godot=<bin>`).
- Rodar sempre da raiz do workspace (`D:/Dev/dev-workspace`).
- Celular com internet (dados móveis ou Wi-Fi qualquer; não precisa estar na mesma rede do PC).

## Passos

1. Na raiz do workspace, suba o túnel. O `--autorizado` é obrigatório: sem ele nada sobe (exit 2), porque a URL
   fica pública.

   ```bash
   node .claude/scripts/playtest-remoto.mjs up ecossistemas/game-gecko/godot-gecko-jump --autorizado
   ```

   O script exporta o preset `Web` para uma pasta temporária (nunca para o repo), serve só em `127.0.0.1`
   (porta 8488, ou a próxima livre) e abre o túnel.

2. Espere a linha com a URL `https://<nome-aleatório>.trycloudflare.com`. Ela só aparece depois de responder 200.
3. Abra a URL no celular. O primeiro carregamento baixa o `.wasm` e o `.pck`; pode demorar alguns segundos.
4. Jogue. Para testar um modo específico em build de debug, use os parâmetros do jogo (ex.: `?modos=teste`).
5. Ao terminar, derrube tudo:

   ```bash
   node .claude/scripts/playtest-remoto.mjs down ecossistemas/game-gecko/godot-gecko-jump
   ```

   O `down` mata só os processos que o `up` registrou, confere que a porta local e a URL pública pararam de
   responder e apaga o export temporário.

Opções do `up`: `--preset=<nome>` (outro preset), `--port=<n>`, `--dir=<pasta já exportada com index.html>` (pula o
export), `--threads` (só se o preset for exportado com threads; manda os cabeçalhos COOP/COEP). O preset atual tem
`thread_support=false`, então não use `--threads`.

## Verificação

- O `up` imprime a URL e sai com exit 0; abrir a URL no navegador mostra o jogo.
- Depois do `down`, a mesma URL deixa de responder e `http://127.0.0.1:8488/` também.
- Estado do túnel: `<pasta temporária do sistema>/claude-playtest/godot-gecko-jump.json` (URL, porta, PIDs).

## Troubleshooting

- **`a URL do tunel e PUBLICA ... Nada subiu` (exit 2):** faltou `--autorizado`.
- **`ja no ar: <url> — rode down antes de subir de novo`:** sobrou um túnel de antes. Rode o `down` e suba de novo.
- **`export "Web" nao gerou index.html`:** faltam os export templates ou o preset falhou. Confira a saída citada no
  erro e rode o export manualmente pela Godot.
- **`nenhuma porta livre perto de 8488`:** libere a porta ou passe outra com `--port=`.
- **Túnel não sobe em 60 s:** o `cloudflared` não alcançou a Cloudflare (rede/firewall). Tente de novo; o script
  derruba o que subiu e não deixa processo órfão.
- **Tela preta ou erro de `SharedArrayBuffer` no celular:** o export foi feito com threads; suba com `--threads`.
- **Link antigo parou de funcionar:** o quick tunnel muda de URL a cada `up`; use sempre a última impressa.
