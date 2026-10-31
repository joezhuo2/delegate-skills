#!/usr/bin/env node
const fs = require('fs');
const os = require('os');
const path = require('path');

const src = path.join(__dirname, '..', 'skills');
const cfg = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
const dest = path.join(cfg, 'skills');
const stateFile = path.join(cfg, 'delegate-skills.json');
const names = fs.readdirSync(src);
const parts = { codex: 'codex-delegate', kiro: 'kiro-delegate' };

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
  console.error(`unknown part '${arg}'; use codex, kiro or all`);
  process.exit(1);
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
} else if (cmd === 'uninstall') {
  for (const n of names) {
    fs.rmSync(path.join(dest, n), { recursive: true, force: true });
    console.log(`removed ${n}`);
  }
  fs.rmSync(path.join(cfg, 'commands', 'delegate.md'), { force: true });
} else if (cmd === 'disable' || cmd === 'enable') {
  const s = readState();
  const off = new Set(s.disabled || []);
  for (const t of targets(arg)) cmd === 'disable' ? off.add(t) : off.delete(t);
  s.disabled = [...off];
  writeState(s);
  console.log(`disabled: ${s.disabled.join(', ') || 'none'}`);
} else if (cmd === 'status') {
  const off = readState().disabled || [];
  for (const t of Object.keys(parts)) console.log(`${t}: ${off.includes(t) ? 'disabled' : 'enabled'}`);
} else {
  console.error('usage: delegate-skills [install|uninstall|enable <codex|kiro|all>|disable <codex|kiro|all>|status]');
  process.exit(1);
}
