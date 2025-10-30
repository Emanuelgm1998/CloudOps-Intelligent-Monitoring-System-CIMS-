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
