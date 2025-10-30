// src/server.js
require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const bodyParser = require('body-parser');
const logger = require('./utils/logger');
const healthRoutes = require('./routes/health');
const monitorRoutes = require('./routes/monitor');
const automationRoutes = require('./routes/automation');
const metricsRoutes = require('./routes/metrics');
const { appendLog } = require('./monitor/logs');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(helmet());
app.use(bodyParser.json());

// logging básico
app.use((req, res, next) => {
  logger.info({ msg: 'request', method: req.method, path: req.path });
  next();
});

// 👇 Ruta de bienvenida para que Codespaces no muestre error en “/”
app.get('/', (req, res) => {
  res.json({
    app: 'CloudOps Intelligent Monitoring System (CIMS)',
    status: 'ok',
    message: 'Welcome to CIMS. Use /health, /status, /logs, /metrics or POST /automation/... ',
    docs: [
      { method: 'GET', path: '/health', desc: 'Healthcheck simple' },
      { method: 'GET', path: '/status', desc: 'Métricas + alertas (IA por reglas)' },
      { method: 'GET', path: '/logs', desc: 'Últimos logs del sistema' },
      { method: 'GET', path: '/metrics', desc: 'Export Prometheus' },
      { method: 'POST', path: '/automation/cleanup', desc: 'Limpieza de temporales' },
      { method: 'POST', path: '/automation/restart', body: '{ "service": "webserver" }' }
    ]
  });
});

// rutas reales
app.use('/', healthRoutes);
app.use('/', monitorRoutes);
app.use('/automation', automationRoutes);
app.use('/', metricsRoutes);

// manejador de errores
app.use((err, req, res, next) => {
  logger.error({ msg: 'error', error: err.message, stack: err.stack });
  appendLog({ type: 'error', msg: err.message });
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  logger.info(`CIMS server listening on port ${PORT}`);
  appendLog({ type: 'startup', msg: `CIMS server started on port ${PORT}` });
});
