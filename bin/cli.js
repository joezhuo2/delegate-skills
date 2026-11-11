#!/usr/bin/env node
const fs = require('fs');
const os = require('os');
const path = require('path');

const src = path.join(__dirname, '..', 'skills');
const cfg = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const dest = path.join(cfg, 'skills');
const stateFile = path.join(cfg, 'delegate-skills.json');
const names = fs.readdirSync(src);
const parts = { codex: 'codex-delegate', kiro: 'kiro-delegate', gemini: 'gemini-delegate', qwen: 'qwen-delegate', copilot: 'copilot-delegate', claude: 'claude-delegate' };

const readState = () => {
  try { return JSON.parse(fs.readFileSync(stateFile, 'utf8')); } catch { return { disabled: [] }; }
};
const writeState = (s) => {
  fs.mkdirSync(cfg, { recursive: true });
  fs.writeFileSync(stateFile, JSON.stringify(s, null, 2));
};
const targets = (arg) => {
  if (arg === 'all') return Object.keys(parts);
  if (parts[arg]) return [arg];
  console.error(`unknown part '${arg}'; use codex, kiro, gemini, qwen, copilot, claude or all`);
  process.exit(1);
};

const levels = ['low', 'medium', 'ultra'];
const hookFile = path.join(cfg, 'delegate-skills', 'level.js');
const hookCmd = `node "${hookFile}"`;
const settingsFile = path.join(cfg, 'settings.json');
const editSettings = (fn) => {
  let s = {};
  if (fs.existsSync(settingsFile)) {
    try { s = JSON.parse(fs.readFileSync(settingsFile, 'utf8')); } catch {
      console.error(`could not parse ${settingsFile}; add a SessionStart hook running ${hookCmd} yourself`);
      return;
    }
  }
  const starts = ((s.hooks ||= {}).SessionStart ||= []);
  s.hooks.SessionStart = fn(starts.filter((g) => !(g.hooks || []).some((h) => h.command === hookCmd)));
  if (!s.hooks.SessionStart.length) delete s.hooks.SessionStart;
  if (!Object.keys(s.hooks).length) delete s.hooks;
  fs.writeFileSync(settingsFile, JSON.stringify(s, null, 2));
};

const [cmd = 'install', arg] = process.argv.slice(2);
if (cmd === 'install') {
  fs.mkdirSync(dest, { recursive: true });
  for (const n of names) {
    fs.cpSync(path.join(src, n), path.join(dest, n), { recursive: true });
    console.log(`installed ${n} -> ${path.join(dest, n)}`);
  }
  fs.mkdirSync(path.join(cfg, 'commands'), { recursive: true });
  fs.copyFileSync(path.join(__dirname, '..', 'commands', 'delegate.md'), path.join(cfg, 'commands', 'delegate.md'));
  fs.mkdirSync(path.dirname(hookFile), { recursive: true });
  fs.copyFileSync(path.join(__dirname, '..', 'hooks', 'level.js'), hookFile);
  editSettings((g) => [...g, { hooks: [{ type: 'command', command: hookCmd }] }]);
  console.log(`installed SessionStart hook -> ${settingsFile}`);
} else if (cmd === 'uninstall') {
  for (const n of names) {
    fs.rmSync(path.join(dest, n), { recursive: true, force: true });
    console.log(`removed ${n}`);
  }
  fs.rmSync(path.join(cfg, 'commands', 'delegate.md'), { force: true });
  fs.rmSync(path.dirname(hookFile), { recursive: true, force: true });
  if (fs.existsSync(settingsFile)) editSettings((g) => g);
} else if (levels.includes(cmd) || cmd === 'level') {
  const lv = cmd === 'level' ? arg : cmd;
  if (!levels.includes(lv)) { console.error('use: low, medium or ultra'); process.exit(1); }
  const s = readState();
  s.level = lv;
  writeState(s);
  console.log(`level: ${lv} (applies to new Claude Code sessions)`);
} else if (cmd === 'disable' || cmd === 'enable') {
  const s = readState();
  const off = new Set(s.disabled || []);
  for (const t of targets(arg)) cmd === 'disable' ? off.add(t) : off.delete(t);
  s.disabled = [...off];
  writeState(s);
  console.log(`disabled: ${s.disabled.join(', ') || 'none'}`);
} else if (cmd === 'status') {
  const s = readState();
  const off = s.disabled || [];
  console.log(`level: ${levels.includes(s.level) ? s.level : 'medium'}`);
  for (const t of Object.keys(parts)) console.log(`${t}: ${off.includes(t) ? 'disabled' : 'enabled'}`);
} else {
  console.error('usage: delegate-skills [install|uninstall|low|medium|ultra|enable <part|all>|disable <part|all>|status]');
  process.exit(1);
}
