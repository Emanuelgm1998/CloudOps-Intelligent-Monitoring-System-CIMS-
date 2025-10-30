const express = require('express');
const router = express.Router();
const { getCpuUsage } = require('../monitor/cpu');
const { getMemoryUsage } = require('../monitor/memory');
const { getLogs } = require('../monitor/logs');
const { evaluateRules } = require('../ai/predictAnomaly');

router.get('/status', (req, res) => {
  const cpu = getCpuUsage();
  const memory = getMemoryUsage();
  const logs = getLogs(50);
  const metrics = {
    cpu,
    memory,
    logs: {
      count: logs.length
    }
  };
  const alerts = evaluateRules(metrics);

  res.json({
    status: 'ok',
    metrics,
    alerts
  });
});

router.get('/logs', (req, res) => {
  const logs = getLogs(100);
  res.json({
    status: 'ok',
    logs
  });
});

module.exports = router;
