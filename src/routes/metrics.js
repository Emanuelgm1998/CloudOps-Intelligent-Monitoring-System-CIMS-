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
