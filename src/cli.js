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
