#!/usr/bin/env bash
# ==========================================
# CloudOps Intelligent Monitoring System (CIMS)
# Setup directo en el directorio actual
# ==========================================
set -e

echo "[CIMS] -> creando estructura en $(pwd)"

# 1. package.json
cat > package.json <<'EOF'
{
  "name": "cloudops-intelligent-monitoring",
  "version": "1.0.0",
  "description": "CloudOps Intelligent Monitoring System (CIMS) - monitoring, automation, security, metrics, CLI. Designed for GitHub Codespaces.",
  "main": "src/server.js",
  "scripts": {
    "start": "node src/server.js",
    "dev": "node src/server.js",
    "lint": "echo \"(optional) add eslint\""
  },
  "author": "Emanuel Gonzalez Michea",
  "license": "MIT",
  "dependencies": {
    "axios": "^1.7.9",
    "dotenv": "^16.4.5",
    "express": "^4.21.1",
    "helmet": "^7.1.0",
    "joi": "^17.13.3",
    "prom-client": "^15.1.3",
    "winston": "^3.15.0",
    "body-parser": "^1.20.3"
  }
}
EOF

# 2. .env
cat > .env <<'EOF'
PORT=3000
APP_ENV=development
LOG_LEVEL=info
AI_RULESET_PATH=./src/ai/rules.json
EOF

# 3. start.sh
cat > start.sh <<'EOF'
#!/usr/bin/env bash
set -e

echo "[CIMS] -> checking dependencies..."
if [ ! -d "node_modules" ]; then
  echo "[CIMS] -> installing npm packages..."
  npm install
else
  echo "[CIMS] -> node_modules found, skipping npm install."
fi

echo "[CIMS] -> starting application..."
npm run start
EOF
chmod +x start.sh

# 4. directorios
mkdir -p src/monitor
mkdir -p src/automation
mkdir -p src/ai
mkdir -p src/utils
mkdir -p src/routes
mkdir -p data
mkdir -p cli

# 5. src/utils/logger.js
cat > src/utils/logger.js <<'EOF'
const winston = require('winston');

const logLevel = process.env.LOG_LEVEL || 'info';

const logger = winston.createLogger({
  level: logLevel,
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console()
  ]
});

module.exports = logger;
EOF

# 6. src/monitor/cpu.js
cat > src/monitor/cpu.js <<'EOF'
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
EOF

# 7. src/monitor/memory.js
cat > src/monitor/memory.js <<'EOF'
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
EOF

# 8. src/monitor/logs.js
cat > src/monitor/logs.js <<'EOF'
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
EOF

# 9. src/automation/cleanup.js
cat > src/automation/cleanup.js <<'EOF'
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
EOF

# 10. src/automation/restartService.js
cat > src/automation/restartService.js <<'EOF'
const { appendLog } = require('../monitor/logs');

function restartService(serviceName = 'webserver') {
  const msg = `Service "${serviceName}" restarted successfully (simulated).`;
  appendLog({ type: 'automation', action: 'restartService', service: serviceName, msg });
  return { status: 'ok', service: serviceName, message: msg };
}

module.exports = { restartService };
EOF

# 11. src/ai/rules.json
cat > src/ai/rules.json <<'EOF'
{
  "version": "1.0.0",
  "rules": [
    {
      "name": "High CPU",
      "condition": {
        "metric": "cpu.load1_pct",
        "operator": ">",
        "value": 75
      },
      "action": "ALERT_HIGH_CPU"
    },
    {
      "name": "High Memory",
      "condition": {
        "metric": "memory.used_pct",
        "operator": ">",
        "value": 80
      },
      "action": "ALERT_HIGH_MEMORY"
    },
    {
      "name": "Log spikes",
      "condition": {
        "metric": "logs.count",
        "operator": ">",
        "value": 100
      },
      "action": "ALERT_LOG_SPIKE"
    }
  ]
}
EOF

# 12. src/ai/predictAnomaly.js
cat > src/ai/predictAnomaly.js <<'EOF'
const fs = require('fs');
const path = require('path');

function evaluateRules(metrics, rulesetPath = process.env.AI_RULESET_PATH || './src/ai/rules.json') {
  const fullPath = path.resolve(rulesetPath);
  const data = JSON.parse(fs.readFileSync(fullPath, 'utf8'));
  const alerts = [];

  data.rules.forEach(rule => {
    const { metric, operator, value } = rule.condition;
    const metricValue = metric.split('.').reduce((acc, key) => acc && acc[key], metrics);

    if (metricValue === undefined) return;

    let triggered = false;
    switch (operator) {
      case '>':
        triggered = metricValue > value;
        break;
      case '>=':
        triggered = metricValue >= value;
        break;
      case '<':
        triggered = metricValue < value;
        break;
      case '<=':
        triggered = metricValue <= value;
        break;
      case '==':
        triggered = metricValue == value;
        break;
      default:
        triggered = false;
    }

    if (triggered) {
      alerts.push({
        rule: rule.name,
        action: rule.action,
        metric,
        metricValue,
        threshold: value
      });
    }
  });

  return alerts;
}

module.exports = { evaluateRules };
EOF

# 13. src/routes/health.js
cat > src/routes/health.js <<'EOF'
const express = require('express');
const router = express.Router();

router.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    ts: new Date().toISOString()
  });
});

module.exports = router;
EOF

# 14. src/routes/monitor.js
cat > src/routes/monitor.js <<'EOF'
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
EOF

# 15. src/routes/automation.js
cat > src/routes/automation.js <<'EOF'
const express = require('express');
const Joi = require('joi');
const { cleanupTemp } = require('../automation/cleanup');
const { restartService } = require('../automation/restartService');

const router = express.Router();

router.post('/cleanup', (req, res) => {
  const result = cleanupTemp();
  res.json(result);
});

router.post('/restart', (req, res) => {
  const schema = Joi.object({
    service: Joi.string().default('webserver')
  });

  const { error, value } = schema.validate(req.body || {});
  if (error) {
    return res.status(400).json({ error: error.message });
  }

  const result = restartService(value.service);
  res.json(result);
});

module.exports = router;
EOF

# 16. src/routes/metrics.js
cat > src/routes/metrics.js <<'EOF'
const express = require('express');
const client = require('prom-client');

const router = express.Router();

const register = new client.Registry();
client.collectDefaultMetrics({ register });

router.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

module.exports = router;
EOF

# 17. src/cli.js
cat > src/cli.js <<'EOF'
const axios = require('axios');

const BASE_URL = process.env.CIMS_BASE_URL || 'http://localhost:3000';

async function main() {
  const args = process.argv.slice(2);
  const cmd = args[0];

  if (!cmd) {
    console.log('CIMS CLI');
    console.log('Usage:');
    console.log('  node src/cli.js status');
    console.log('  node src/cli.js cleanup');
    console.log('  node src/cli.js restart <serviceName>');
    process.exit(0);
  }

  try {
    switch (cmd) {
      case 'status': {
        const res = await axios.get(`${BASE_URL}/status`);
        console.log(JSON.stringify(res.data, null, 2));
        break;
      }
      case 'cleanup': {
        const res = await axios.post(`${BASE_URL}/automation/cleanup`);
        console.log(JSON.stringify(res.data, null, 2));
        break;
      }
      case 'restart': {
        const service = args[1] || 'webserver';
        const res = await axios.post(`${BASE_URL}/automation/restart`, { service });
        console.log(JSON.stringify(res.data, null, 2));
        break;
      }
      default:
        console.log(`Unknown command: ${cmd}`);
        process.exit(1);
    }
  } catch (err) {
    console.error('Error calling API:', err.message);
    process.exit(1);
  }
}

main();
EOF

# 18. cli/cloudopsctl.sh
cat > cli/cloudopsctl.sh <<'EOF'
#!/usr/bin/env bash
CMD=$1
shift || true

if [ -z "$CMD" ]; then
  echo "CloudOps CLI"
  echo "Usage:"
  echo "  ./cli/cloudopsctl.sh status"
  echo "  ./cli/cloudopsctl.sh cleanup"
  echo "  ./cli/cloudopsctl.sh restart <service>"
  exit 0
fi

node src/cli.js "$CMD" "$@"
EOF
chmod +x cli/cloudopsctl.sh

# 19. src/server.js
cat > src/server.js <<'EOF'
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
EOF

# 20. Dockerfile
cat > Dockerfile <<'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
ENV PORT=3000
EXPOSE 3000
CMD ["npm","run","start"]
EOF

# 21. docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: "3.8"
services:
  cims:
    build: .
    container_name: cims_app
    ports:
      - "3000:3000"
    environment:
      - PORT=3000
      - APP_ENV=production
      - LOG_LEVEL=info
    restart: unless-stopped
EOF

# 22. README.md
cat > README.md <<'EOF'
# CloudOps Intelligent Monitoring System (CIMS)

Sistema de monitoreo + automatización + métricas + "IA por reglas" pensado para demostrar nivel de Arquitectura Cloud / SysOps en GitHub.

## Ejecutar
./start.sh

## Endpoints
- GET /health
- GET /status
- GET /logs
- POST /automation/cleanup
- POST /automation/restart
- GET /metrics

## CLI
./cli/cloudopsctl.sh status
./cli/cloudopsctl.sh cleanup
./cli/cloudopsctl.sh restart api-gateway
EOF

# 23. data/logs.json
cat > data/logs.json <<'EOF'
[]
EOF

echo "[CIMS] -> estructura creada."
echo "[CIMS] -> ahora ejecuta: npm install"
echo "[CIMS] -> luego: ./start.sh"
echo "[CIMS] -> en otra terminal: ./cli/cloudopsctl.sh status"
