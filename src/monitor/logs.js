const fs = require('fs');
const path = require('path');

const LOG_FILE = path.join(__dirname, '../../data/logs.json');

function ensureLogFile() {
  if (!fs.existsSync(LOG_FILE)) {
    fs.writeFileSync(LOG_FILE, JSON.stringify([], null, 2));
  }
}

function appendLog(entry) {
  ensureLogFile();
  const data = JSON.parse(fs.readFileSync(LOG_FILE, 'utf8'));
  data.push({
    ...entry,
    ts: new Date().toISOString()
  });
  fs.writeFileSync(LOG_FILE, JSON.stringify(data, null, 2));
}

function getLogs(limit = 50) {
  ensureLogFile();
  const data = JSON.parse(fs.readFileSync(LOG_FILE, 'utf8'));
  return data.slice(-limit);
}

module.exports = { appendLog, getLogs };
