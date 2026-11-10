#!/usr/bin/env node
const fs = require('fs');
const os = require('os');
const path = require('path');

const cfg = process.env.CLAUDE_CONFIG_DIR || path.join(os.homedir(), '.claude');
let state = {};
try { state = JSON.parse(fs.readFileSync(path.join(cfg, 'delegate-skills.json'), 'utf8')); } catch {}
const level = ['low', 'medium', 'ultra'].includes(state.level) ? state.level : 'medium';
const off = state.disabled || [];
const on = ['codex', 'kiro'].filter((p) => !off.includes(p));

const rules = {
  low: 'Use codex-delegate / kiro-delegate ONLY when the user explicitly asks to delegate. Otherwise do the work yourself or with normal subagents.',
  medium: 'Use codex-delegate / kiro-delegate when a task fits their "when to delegate" rules; otherwise do the work yourself or with normal subagents.',
  ultra: 'Prefer codex-delegate / kiro-delegate over Claude subagents AND over doing the work yourself. Delegate every task a worker can do (implementation, tests, docs, reviews, research, refactors); keep only orchestration, review of worker output, and work no worker can do. Fall back to subagents or yourself only when every gate blocks or the worker fails.',
};

if (!on.length) console.log('delegate-skills: all workers disabled; do not delegate.');
else console.log(`delegate-skills level: ${level} (enabled: ${on.join(', ')}). ${rules[level]}`);
