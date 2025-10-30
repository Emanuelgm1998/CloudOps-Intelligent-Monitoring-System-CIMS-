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
app.use((req, res, next) => {
  logger.info({ msg: 'request', method: req.method, path: req.path });
  next();
});

app.use('/', healthRoutes);
app.use('/', monitorRoutes);
app.use('/automation', automationRoutes);
app.use('/', metricsRoutes);

app.use((err, req, res, next) => {
  logger.error({ msg: 'error', error: err.message, stack: err.stack });
  appendLog({ type: 'error', msg: err.message });
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(PORT, () => {
  logger.info(`CIMS server listening on port ${PORT}`);
  appendLog({ type: 'startup', msg: `CIMS server started on port ${PORT}` });
});
