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
