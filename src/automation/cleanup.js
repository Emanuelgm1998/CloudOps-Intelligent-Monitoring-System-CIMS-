const fs = require('fs');
const path = require('path');
const { appendLog } = require('../monitor/logs');

const TMP_DIR = path.join(__dirname, '../../data/tmp');

function cleanupTemp() {
  if (!fs.existsSync(TMP_DIR)) {
    fs.mkdirSync(TMP_DIR, { recursive: true });
  }
  const files = fs.readdirSync(TMP_DIR);
  files.forEach(f => {
    fs.unlinkSync(path.join(TMP_DIR, f));
  });
  appendLog({ type: 'automation', action: 'cleanupTemp', msg: `Cleaned ${files.length} temp files` });
  return { status: 'ok', cleaned: files.length };
}

module.exports = { cleanupTemp };
