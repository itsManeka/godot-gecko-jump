-- Exporta a folha final do gecko animado: uma linha por animacao (ordem das tags), colunas = frame
-- da animacao, sobras transparentes. Uso (de dentro do repo):
--   <aseprite> -b assets/src/gecko-<cor>-anim.aseprite --script-param cor=<cor> --script assets/src/export_gecko_anim.lua
-- Grava assets/gecko-<cor>.png e assets/src/gecko-<cor>.json (formato json-array do Aseprite, quadros na
-- posicao da folha final, com meta.frameTags e duracao em ms).
local cor = app.params["cor"]
if cor == nil or cor == "" then
  error("falta --script-param cor=<verde|amarelo|azul|vermelho>")
end
local spr = app.sprite
if spr == nil then
  error("nenhum sprite aberto")
end
if #spr.tags == 0 then
  error("sprite sem tags")
end

local ANIMACOES = { "idle", "run", "jump", "fall", "lose", "color_change" }
local COLUNAS = 4
local W, H = spr.width, spr.height
local tags = {}
for _, t in ipairs(spr.tags) do
  tags[t.name] = t
end

local sheet = Image(COLUNAS * W, #ANIMACOES * H, spr.colorMode)
local quadros = {}
local frame_tags = {}
for linha, nome in ipairs(ANIMACOES) do
  local t = tags[nome]
  if t == nil then
    error("tag ausente: " .. nome)
  end
  local n = t.toFrame.frameNumber - t.fromFrame.frameNumber + 1
  if n > COLUNAS then
    error("tag " .. nome .. " com mais de " .. COLUNAS .. " frames")
  end
  for k = 0, n - 1 do
    local fn = t.fromFrame.frameNumber + k
    local img = Image(W, H, spr.colorMode)
    img:drawSprite(spr, fn, 0, 0)
    sheet:drawImage(img, Point(k * W, (linha - 1) * H))
    quadros[#quadros + 1] = {
      filename = string.format("%s %d", nome, k),
      frame = { x = k * W, y = (linha - 1) * H, w = W, h = H },
      rotated = false,
      trimmed = false,
      spriteSourceSize = { x = 0, y = 0, w = W, h = H },
      sourceSize = { w = W, h = H },
      duration = math.floor(spr.frames[fn].duration * 1000 + 0.5),
    }
  end
  frame_tags[#frame_tags + 1] = {
    name = nome,
    from = #quadros - n,
    to = #quadros - 1,
    direction = "forward",
  }
end

local png = "assets/gecko-" .. cor .. ".png"
local data = "assets/src/gecko-" .. cor .. ".json"
local out = Sprite(sheet.width, sheet.height, spr.colorMode)
if spr.colorMode == ColorMode.INDEXED then
  out:setPalette(spr.palettes[1])
end
out.cels[1].image = sheet
out:saveCopyAs(png)

local doc = {
  frames = quadros,
  meta = {
    app = "aseprite",
    image = "gecko-" .. cor .. ".png",
    format = "RGBA8888",
    size = { w = sheet.width, h = sheet.height },
    scale = "1",
    frameTags = frame_tags,
  },
}
local f = io.open(data, "w")
f:write(json.encode(doc))
f:write("\n")
f:close()
print(string.format("%s: %dx%d, %d quadros", png, sheet.width, sheet.height, #quadros))
