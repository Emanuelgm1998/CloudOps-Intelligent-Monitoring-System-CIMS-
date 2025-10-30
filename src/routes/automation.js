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
