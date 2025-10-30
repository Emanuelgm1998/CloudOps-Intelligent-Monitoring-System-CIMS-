const os = require('os');

function getMemoryUsage() {
  const total = os.totalmem();
  const free = os.freemem();
  const used = total - free;
  return {
    total,
    free,
    used,
    used_pct: Number(((used / total) * 100).toFixed(2))
  };
}

module.exports = { getMemoryUsage };
