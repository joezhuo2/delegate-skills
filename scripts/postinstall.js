const { spawnSync } = require('child_process');
const path = require('path');

const r = spawnSync(process.execPath, [path.join(__dirname, '..', 'bin', 'cli.js'), 'install'], { stdio: 'inherit' });
if (r.status !== 0) console.warn('delegate-skills: auto-install failed; run `delegate-skills install`');
