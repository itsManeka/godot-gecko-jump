// Oraculo do repo para o verify-wave do dev-workspace: `node .verify.mjs <wave>` (exit 0 = ok).
// Godot nem sempre muda o exit code em erro de script, entao o stderr e varrido atras de ERROR.
// Caminho do Godot: env GODOT_PATH (Godot 4) / GODOT3_PATH, senao `ecosystems.game-gecko.tools` do workspace-config.
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.dirname(fileURLToPath(import.meta.url));
const RUN_SECONDS = 10;

function workspaceTools() {
  const cfg = path.resolve(root, '..', '..', '..', '.claude', 'workspace-config.json');
  if (!fs.existsSync(cfg)) return {};
  return JSON.parse(fs.readFileSync(cfg, 'utf8')).ecosystems?.['game-gecko']?.tools ?? {};
}

// expectTimeout: o Godot 3 nao tem --quit-after, entao a partida roda ate o timeout e ser morta e o esperado
function run(bin, args, timeoutMs = 120_000, expectTimeout = false) {
  const r = spawnSync(bin, args, { cwd: root, encoding: 'utf8', timeout: timeoutMs });
  const out = `${r.stdout ?? ''}${r.stderr ?? ''}`;
  const error = expectTimeout && r.error?.code === 'ETIMEDOUT' ? undefined : r.error;
  return { status: r.status, out, error };
}

function errorsIn(out, ignore = []) {
  return out
    .split(/\r?\n/)
    .filter((l) => /(SCRIPT ERROR|^ERROR:|Parse Error)/.test(l))
    .filter((l) => !ignore.some((re) => re.test(l)));
}

function gdFiles(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    if (e.name.startsWith('.') || e.name === 'addons' || e.name === 'export') return [];
    const p = path.join(dir, e.name);
    return e.isDirectory() ? gdFiles(p) : e.name.endsWith('.gd') ? [p] : [];
  });
}

const project = fs.readFileSync(path.join(root, 'project.godot'), 'utf8');
const isGodot4 = /config_version=5/.test(project);
const tools = workspaceTools();
const bin = isGodot4 ? process.env.GODOT_PATH || tools.godot : process.env.GODOT3_PATH || tools.godot3;
if (!bin || !fs.existsSync(bin)) {
  console.error(`.verify.mjs: Godot ${isGodot4 ? '4' : '3'} nao encontrado (${bin ?? 'sem caminho'})`);
  process.exit(2);
}

const failures = [];
const step = (name, res, ignore) => {
  const errs = errorsIn(res.out, ignore);
  if (res.error) failures.push(`${name}: ${res.error.message}`);
  else if (errs.length) failures.push(`${name}:\n  ${errs.join('\n  ')}`);
  else console.log(`ok  ${name}`);
};

if (isGodot4) {
  step('import', run(bin, ['--headless', '--path', '.', '--import']));
  for (const f of gdFiles(root)) {
    const res = `res://${path.relative(root, f).split(path.sep).join('/')}`;
    step(`check ${res}`, run(bin, ['--headless', '--path', '.', '--check-only', '--script', res]));
  }
  if (fs.existsSync(path.join(root, 'addons', 'gut'))) {
    const gut = run(bin, ['--headless', '--path', '.', '-s', 'addons/gut/gut_cmdln.gd', '-gdir=res://test', '-gexit'], 600_000);
    if (gut.status !== 0) failures.push(`gut: exit ${gut.status}\n${gut.out.slice(-2000)}`);
    else step('gut', gut);
  }
  step(`run ${RUN_SECONDS}s`, run(bin, ['--headless', '--path', '.', '--quit-after', String(RUN_SECONDS * 60)]));
} else {
  // Godot 3 (prototipo antes da migracao): editor --quit importa; o erro de recurso ciclico do import e conhecido.
  // O editor do 3 reserializa o project.godot ao abrir; o oraculo nao pode sujar a arvore.
  const projectPath = path.join(root, 'project.godot');
  const imported = run(bin, ['--no-window', '--path', '.', '-e', '--quit']);
  fs.writeFileSync(projectPath, project);
  step('import (godot 3)', imported, [/Another resource is loaded from path/]);
  step(`run ${RUN_SECONDS}s (godot 3)`, run(bin, ['--no-window', '--path', '.', '--fixed-fps', '60'], RUN_SECONDS * 1000, true));
}

if (failures.length) {
  console.error(`FAIL\n${failures.join('\n')}`);
  process.exit(1);
}
console.log('PASS');
