const os = require('os');

function getCpuUsage() {
  const load = os.loadavg();
  const cpuCount = os.cpus().length;
  return {
    cores: cpuCount,
    load1: load[0],
    load5: load[1],
    load15: load[2],
    load1_pct: Number(((load[0] / cpuCount) * 100).toFixed(2))
  };
}

module.exports = { getCpuUsage };
