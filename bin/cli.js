#!/usr/bin/env node
const fs = require('fs');
const os = require('os');
const path = require('path');

const src = path.join(__dirname, '..', 'skills');
const dest = path.join(process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude'), 'skills');
const names = fs.readdirSync(src);

const cmd = process.argv[2] || 'install';
if (cmd === 'install') {
  fs.mkdirSync(dest, { recursive: true });
  for (const n of names) {
    fs.cpSync(path.join(src, n), path.join(dest, n), { recursive: true });
    console.log(`installed ${n} -> ${path.join(dest, n)}`);
  }
} else if (cmd === 'uninstall') {
  for (const n of names) {
    fs.rmSync(path.join(dest, n), { recursive: true, force: true });
    console.log(`removed ${n}`);
  }
} else {
  console.error('usage: delegate-skills [install|uninstall]');
  process.exit(1);
}
