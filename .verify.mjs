// Oraculo do repo para o verify-wave do dev-workspace: `node .verify.mjs <wave>` (exit 0 = ok, 1 = falha, 2 = ambiente).
// Godot 4 apenas. Godot nem sempre muda o exit code em erro de script, entao o stderr e varrido atras de ERROR.
// A checagem de scripts usa .verify-compile.gd (compila todos os .gd com os autoloads registrados), porque o
// `--check-only --script` do 4.7.2 nao carrega autoload e acusa `Identifier not found: Global`.
// Caminho do Godot: env GODOT_PATH, senao `ecosystems.game-gecko.tools.godot` do workspace-config.
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

function run(bin, args, timeoutMs = 120_000) {
  const r = spawnSync(bin, args, { cwd: root, encoding: 'utf8', timeout: timeoutMs });
  const out = `${r.stdout ?? ''}${r.stderr ?? ''}`;
  return { status: r.status, out, error: r.error };
}

function warningsIn(out) {
  return out.split(/\r?\n/).filter((l) => l.startsWith('WARNING:'));
}

function errorsIn(out) {
  return out.split(/\r?\n/).filter((l) => /(SCRIPT ERROR|^ERROR:|Parse Error)/.test(l));
}

const project = fs.readFileSync(path.join(root, 'project.godot'), 'utf8');
if (!/config_version=5/.test(project)) {
  console.error('.verify.mjs: project.godot sem config_version=5 (Godot 4). O ramo Godot 3 foi removido; migre o projeto antes.');
  process.exit(2);
}
const bin = process.env.GODOT_PATH || workspaceTools().godot;
if (!bin || !fs.existsSync(bin)) {
  console.error(`.verify.mjs: Godot 4 nao encontrado (${bin ?? 'sem caminho'})`);
  process.exit(2);
}

const failures = [];
const step = (name, res) => {
  const errs = errorsIn(res.out);
  for (const w of warningsIn(res.out)) console.log(`warn ${w}`);
  if (res.error) failures.push(`${name}: ${res.error.message}`);
  else if (errs.length) failures.push(`${name}:\n  ${errs.join('\n  ')}`);
  else console.log(`ok  ${name}`);
};

step('import', run(bin, ['--headless', '--path', '.', '--import']));
step('compile all .gd', run(bin, ['--headless', '--path', '.', '-s', 'res://.verify-compile.gd']));
if (fs.existsSync(path.join(root, 'addons', 'gut'))) {
  const gut = run(bin, ['--headless', '--path', '.', '-s', 'addons/gut/gut_cmdln.gd', '-gdir=res://test', '-gexit'], 600_000);
  // Resumo do GUT 9.x: linha "Tests   <N>" em "Totals" (com codigos ANSI no meio). Pending/risky vem em linhas
  // proprias do resumo e nao casam com errorsIn; so exit != 0, erro de script ou N = 0 reprovam.
  const gutPlain = gut.out.replace(/\x1b\[[0-9;]*m/g, '');
  const gutTotal = /^Tests\s+(\d+)\s*$/m.exec(gutPlain);
  const gutCount = gutTotal ? Number(gutTotal[1]) : null;
  if (gut.error) failures.push(`gut: ${gut.error.message}`);
  else if (gut.status !== 0) failures.push(`gut: exit ${gut.status}\n${gutPlain.slice(-2000)}`);
  else if (errorsIn(gutPlain).length) step('gut', { ...gut, out: gutPlain });
  else if (!gutCount) failures.push(`gut: nenhum teste executado (total ${gutCount ?? 'nao encontrado na saida'})\n${gutPlain.slice(-1000)}`);
  else step(`gut (${gutCount} tests)`, { ...gut, out: gutPlain });
}
step(`run ${RUN_SECONDS}s`, run(bin, ['--headless', '--path', '.', '--quit-after', String(RUN_SECONDS * 60)]));

if (failures.length) {
  console.error(`FAIL\n${failures.join('\n')}`);
  process.exit(1);
}
console.log('PASS');
