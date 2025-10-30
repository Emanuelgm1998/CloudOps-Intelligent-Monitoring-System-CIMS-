const { appendLog } = require('../monitor/logs');

function restartService(serviceName = 'webserver') {
  const msg = `Service "${serviceName}" restarted successfully (simulated).`;
  appendLog({ type: 'automation', action: 'restartService', service: serviceName, msg });
  return { status: 'ok', service: serviceName, message: msg };
}

module.exports = { restartService };
