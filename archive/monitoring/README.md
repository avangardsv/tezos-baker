# Tezos Node Monitoring Stack

Based on official documentation: https://octez.tezos.com/user/node-monitoring.html

## Components
- **Prometheus**: Scrapes metrics from Tezos node (port 9095)
- **Grafana**: Visualizes metrics with dashboards

## Quick Start

1. Ensure Tezos node is running and exposing metrics on port 9095
2. Start monitoring stack:
   ```bash
   cd monitoring
   docker-compose up -d
   ```

3. Access Grafana: http://localhost:3000
   - Username: admin
   - Password: tezos_monitoring_2026

4. Add Prometheus data source in Grafana:
   - URL: http://prometheus:9090
   - Click "Save & Test"

5. Import official Tezos dashboard (search for "Tezos" in Grafana dashboards)

## Verify Metrics

Check Prometheus is scraping:
```bash
curl http://localhost:9090/api/v1/targets
```

Check node metrics are available:
```bash
curl http://localhost:9095/metrics | head -20
```

## Stop Monitoring

```bash
cd monitoring
docker-compose down
```

## Official Dashboard

Search for "Grafazos" or official Tezos Grafana dashboards in:
- Grafana dashboard repository
- Tezos ecosystem documentation
